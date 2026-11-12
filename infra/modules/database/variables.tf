variable "identifier" {
  description = "Identifier of the RDS instance and prefix for related resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC."
  type        = string
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group (isolated subnets)."
  type        = string
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to PostgreSQL."
  type        = list(string)
  default     = []
}

variable "db_name" {
  description = "Name of the initial database."
  type        = string
}

variable "username" {
  description = "Master username."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL version. A major-only value lets RDS pick the minor."
  type        = string
  default     = "18"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Storage in GiB."
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  description = "Days to keep automated backups."
  type        = number
  default     = 1
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}