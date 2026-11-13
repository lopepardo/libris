data "aws_region" "current" {}

locals {
  container_name = "app"
  aws_region     = data.aws_region.current.region

  environment = [
    { name = "APP_NAME", value = var.app_name },
    { name = "APP_ENV", value = "production" }, # the app only accepts development|test|production
    { name = "APP_VERSION", value = var.app_version },
    { name = "PORT", value = tostring(var.application_port) },
    { name = "LOG_LEVEL", value = var.log_level },
    { name = "DB_HOST", value = var.db_host },
    { name = "DB_PORT", value = tostring(var.db_port) },
    { name = "DB_NAME", value = var.db_name },
    { name = "DB_SSL", value = "true" }, # RDS enforces TLS
  ]

  # ECS reads one JSON key of the secret: "<arn>:<key>::"
  secrets = [
    { name = "DB_USER", valueFrom = "${var.db_secret_arn}:username::" },
    { name = "DB_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" },
  ]
}