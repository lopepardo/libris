output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnets
}

output "database_subnet_group_name" {
  value = module.network.database_subnet_group_name
}

output "ecr_repository_url" {
  value = module.registry.repository_url
}

output "github_role_arn" {
  value = module.github_oidc.role_arn
}