output "application_url" {
  value = "http://${aws_lb.app.dns_name}"
}

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "service_name" {
  value = aws_ecs_service.app.name
}

output "migrate_task_definition" {
  description = "Family of the one-off migration task."
  value       = aws_ecs_task_definition.migrate.family
}

output "tasks_security_group_id" {
  value = aws_security_group.tasks.id
}