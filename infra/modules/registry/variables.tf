variable "repository_name" {
  description = "Name of the ECR repository."
  type        = string
}

variable "max_image_count" {
  description = "Number of most recent images to keep."
  type        = number
  default     = 10
}

variable "force_delete" {
  description = "Delete the repository even if it still has images (needed for terraform destroy)."
  type        = bool
  default     = false
}