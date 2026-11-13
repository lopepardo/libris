output "github_role_arn" {
  value = module.github_oidc.role_arn
}
output "ecr_repository_url" {
  value = module.registry.repository_url
}

# Network
output "vpc_id" {
  value = module.network.vpc_id
}
output "public_subnet_ids" {
  value = module.network.public_subnets
}
output "database_subnet_group_name" {
  value = module.network.database_subnet_group_name
}

# Database
output "db_address" {
  value = module.database.address
}
output "db_secret_arn" {
  value = module.database.master_user_secret_arn
}

# Service
output "application_url" {
  value = module.service.application_url
}
output "ecs_cluster_name" {
  value = module.service.cluster_name
}
output "ecs_service_name" {
  value = module.service.service_name
}
output "migrate_task_definition" {
  value = module.service.migrate_task_definition
}
output "tasks_security_group_id" {
  value = module.service.tasks_security_group_id
}