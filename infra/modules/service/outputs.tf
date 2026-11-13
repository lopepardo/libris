output "application_url" {
  value = "http://${aws_lb.app.dns_name}"
}

output "tasks_security_group_id" {
  value = aws_security_group.tasks.id
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.app.name
}

output "execution_role_arn" {
  value = aws_iam_role.execution.arn
}

output "task_role_arn" {
  value = aws_iam_role.task.arn
}

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "service_name" {
  value = aws_ecs_service.app.name
}

output "app_task_definition" {
  description = "Family of the API task definition."
  value       = aws_ecs_task_definition.app.family
}

output "migrate_task_definition" {
  description = "Family of the one-off migration task."
  value       = aws_ecs_task_definition.migrate.family
}
