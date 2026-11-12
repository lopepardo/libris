data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  project_name      = "libris"
  environment       = "prod"
  name_prefix       = "${local.project_name}-${local.environment}"
  aws_region        = "us-east-1"
  github_repository = "lopepardo/libris"

  tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }

  vpc_cidr           = "10.0.0.0/16"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets     = [for i in range(2) : cidrsubnet(local.vpc_cidr, 8, i)]
  database_subnets   = [for i in range(2) : cidrsubnet(local.vpc_cidr, 8, 20 + i)]
}