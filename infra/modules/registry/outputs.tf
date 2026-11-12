output "repository_url" {
  description = "URL of the repository, without tag or digest."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN of the repository, used to scope IAM permissions."
  value       = aws_ecr_repository.this.arn
}