variable "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions."
  type        = string
}

variable "github_repository" {
  description = "Repository allowed to assume the role, in the form used by the OIDC sub claim (OWNER@ID/REPO@ID with immutable subjects)."
  type        = string
}

variable "allowed_refs" {
  description = "Git refs allowed to assume the role."
  type        = list(string)
  default     = ["refs/heads/main"]
}

variable "ecr_repository_arns" {
  description = "ECR repositories the role may push images to."
  type        = list(string)
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "ecs_task_families" {
  description = "Task definition families the pipeline may run."
  type        = list(string)
}

variable "pass_role_arns" {
  description = "Task and execution roles the pipeline may hand to ECS."
  type        = list(string)
}

variable "log_group_name" {
  description = "Log group the pipeline may read to show migration output."
  type        = string
}