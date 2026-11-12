variable "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions."
  type        = string
}

variable "github_repository" {
  description = "Repository allowed to assume the role, as OWNER/REPO."
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