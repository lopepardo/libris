# Guía de despliegue

Cómo se construye, entrega y opera Libris. Las razones de las decisiones están en la tabla del [README](../README.md).

## 1. Dos caminos

| Cambio                     | Camino                               | Quién          |
| -------------------------- | ------------------------------------ | -------------- |
| Código (`app/`)            | Merge a `main` dispara `deploy.yml`  | GitHub Actions |
| Infraestructura (`infra/`) | `terraform plan` y `terraform apply` | A mano         |

Así el pipeline no necesita acceso al estado de Terraform ni permisos amplios, y un error de infraestructura no viaja con un cambio de código.

## 2. Pipeline

`ci.yml` corre en los pull requests que tocan `app/` y lo reutiliza el despliegue: instala dependencias, aplica las migraciones a un Postgres 18 desechable y ejecuta typecheck, lint y tests.

`deploy.yml` corre al hacer push a `main` (o manualmente):

1. **CI.** Si falla, no continúa.
2. **Build** de dos imágenes arm64 en un runner ARM nativo: `production` y `migrate`. El tag es `<sha>-<intento>`; el número de intento evita choques con los tags inmutables de ECR al reintentar.
3. **Migración.** Registra una revisión de `libris-prod-migrate` con el digest nuevo y la ejecuta una vez, con la red del servicio. Si termina con código distinto de 0, falla y muestra los logs.
4. **Despliegue.** Registra una revisión de `libris-prod` (digest nuevo y `APP_VERSION` = SHA del commit), llama a `update-service` y espera a que se estabilice.
5. **Verificación de rollback.** Con el circuit breaker, un despliegue fallido se revierte y el servicio queda "estable" en la revisión anterior. Por eso el pipeline compara la task definition final con la que registró y falla si difieren.

Solo corre un despliegue a la vez y nunca se cancela uno en curso.

### Autenticación

El workflow asume el rol `libris-github-deploy` por OIDC; no hay claves de AWS en GitHub. El ARN del rol es la variable de repositorio `AWS_ROLE_ARN`.

- La trust policy exige `aud = sts.amazonaws.com` y un `sub` exacto que fija la rama `main`. El repositorio se identifica por sus IDs inmutables (`owner@id/repo@id`), no por nombre; el valor está en `infra/envs/prod/locals.tf` y sale de `gh api repos/<owner>/<repo>/actions/oidc/customization/sub`.
- Permisos: subir y leer imágenes del repositorio de ECR, registrar task definitions, ejecutar las de este cluster, actualizar este servicio, pasar solo los dos roles de ECS y leer los logs de migración.

## 3. Infraestructura

```text
infra/
  modules/
    registry/     ECR (tags inmutables, escaneo al subir, conserva 20 imágenes)
    database/     RDS PostgreSQL 18, security group, secreto administrado
    service/      Cluster, servicio y task definitions de ECS, ALB, roles IAM, logs
    github-oidc/  Confianza OIDC y permisos de despliegue
  envs/prod/      Composición del único entorno
```

- **Estado:** en S3 con bloqueo nativo (`use_lockfile`, Terraform 1.10 o superior), sin DynamoDB.
- **Red:** una VPC con dos subredes públicas (balanceador y tareas) y dos aisladas para la BD, sin NAT. Los security groups se encadenan: internet al ALB por el 80, ALB a las tareas por el 3000, tareas a la BD por el 5432. Las tareas solo salen por el 443 (ECR, Secrets Manager, CloudWatch) y el 5432.
- **Secretos:** RDS genera la contraseña maestra y la guarda en Secrets Manager. ECS inyecta `DB_USER` y `DB_PASSWORD` al iniciar mediante el rol de ejecución, que solo puede leer ese secreto. El rol de la tarea está vacío porque la app no llama a la API de AWS.
- **TLS a la BD:** RDS exige SSL, así que la imagen incluye el bundle de CA de RDS (`NODE_EXTRA_CA_CERTS`), la app usa `DB_SSL=true` y las migraciones de Prisma usan `sslmode=require`.

## 4. Runbook

### Inicializar Terraform

Hace falta una vez por clon del repositorio, y de nuevo al añadir módulos o cambiar la versión de un proveedor.

El bucket de S3 del estado **no** está en `backend.tf` ni lo crea este código: debe existir antes (idealmente con versionado y cifrado activados). Se pasa al inicializar, para no publicar su nombre en el repositorio:

```bash
cd infra/envs/prod
terraform init -backend-config="bucket=<bucket-del-estado>"
```

- El resto de la configuración del backend (clave `libris/prod/statefile.tfstate`, región, cifrado y bloqueo con `use_lockfile`) sí está en `backend.tf`.
- Se necesitan credenciales de AWS con acceso al bucket (`aws sts get-caller-identity` para comprobarlas) y Terraform 1.10 o superior.
- `.terraform.lock.hcl` se versiona para que todos usen las mismas versiones de proveedores; `.terraform/` no.
- Si el backend cambia, repite con `terraform init -reconfigure -backend-config="bucket=..."`.

### Aplicar cambios de infraestructura

```bash
cd infra/envs/prod
terraform fmt -recursive ..
terraform validate
terraform plan -out=tfplan   # un despliegue de código nunca debe aparecer como cambio del servicio
terraform apply tfplan
```

`terraform.tfvars` (ignorado por git) contiene `app_image`, `migrate_image` y `app_version`. Solo importan al crear la pila, porque el servicio ignora los cambios posteriores de la task definition.

### Primer despliegue de una pila nueva

1. Crear el bucket del estado (si no existe), `terraform init` (ver arriba) y `terraform apply -target=module.registry`.
2. Construir y subir a mano las imágenes `production` y `migrate`; poner sus digests en `terraform.tfvars`.
3. `terraform apply` completo y ejecutar la migración una vez.
4. Definir la variable `AWS_ROLE_ARN`. Desde aquí el pipeline se encarga.

### Comprobar el servicio

```bash
aws ecs describe-services --cluster libris-prod-cluster --services libris-prod-service \
  --query 'services[0].{estado:status,corriendo:runningCount,taskDef:taskDefinition}'

aws logs tail /ecs/libris-prod --since 15m --follow
```

La URL pública sale de `terraform output application_url`; prueba `/health`.

### Revertir una versión

Vuelve a ejecutar el workflow sobre el commit anterior, o apunta el servicio a una revisión previa:

```bash
aws ecs update-service --cluster libris-prod-cluster --service libris-prod-service \
  --task-definition libris-prod:<revision>
```

Ninguno de los dos revierte las migraciones, por eso deben ser retrocompatibles: primero se añaden columnas y tablas, y se eliminan en un release posterior.

### Destruir la pila para ahorrar

```bash
cd infra/envs/prod && terraform destroy
```

La BD se crea con `skip_final_snapshot = true` y sin protección contra borrado: destruirla elimina los datos. Si importan, toma antes un snapshot manual. El bucket del estado no lo gestiona este código y se conserva.

## 5. Limitaciones conocidas

- Solo HTTP hasta tener dominio y certificado.
- Sin alarmas: los fallos solo se ven en la consola y los logs.
- BD en una AZ y una sola tarea: una caída de zona o un reemplazo de tarea causa una interrupción breve.
- Terraform no se planifica automáticamente en los pull requests.
