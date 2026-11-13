variable "name_prefix" {
  type = string
}

variable "app_name" {
  description = "Value of APP_NAME."
  type        = string
}

variable "app_version" {
  description = "Value of APP_VERSION (git sha or release)."
  type        = string
}

variable "log_level" {
  type    = string
  default = "info"
}

variable "log_retention_days" {
  type    = number
  default = 14
}

# Network
variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

# Images (by digest, so a deploy is always an immutable artifact)
variable "app_image" {
  description = "API image URI, ending in @sha256:<digest>."
  type        = string

  validation {
    condition     = can(regex("@sha256:[0-9a-f]{64}$", var.app_image))
    error_message = "app_image must end with a SHA-256 digest."
  }
}

variable "migrate_image" {
  description = "Migration image URI, ending in @sha256:<digest>."
  type        = string

  validation {
    condition     = can(regex("@sha256:[0-9a-f]{64}$", var.migrate_image))
    error_message = "migrate_image must end with a SHA-256 digest."
  }
}

# Sizing
variable "application_port" {
  type    = number
  default = 3000
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 1
}

# Database
variable "db_host" {
  type = string
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_name" {
  type = string
}

variable "db_secret_arn" {
  description = "Secrets Manager secret with the DB username and password."
  type        = string
}

variable "database_security_group_id" {
  description = "Security group of the database; the tasks may reach it on 5432."
  type        = string
}