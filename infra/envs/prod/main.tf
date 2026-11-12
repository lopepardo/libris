module "network" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = "${local.name_prefix}-vpc"
  cidr = local.vpc_cidr
  azs  = local.availability_zones

  public_subnets   = local.public_subnets
  database_subnets = local.database_subnets

  # Cost decision: no NAT. ECS tasks live in public subnets and are protected by
  # their security group. The database subnets have no route to the internet.
  enable_nat_gateway = false

  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  enable_dns_support      = true
  enable_dns_hostnames    = true
  map_public_ip_on_launch = false

  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  tags = local.tags
}

module "registry" {
  source = "../../modules/registry"

  repository_name = "${local.project_name}-api"
  force_delete    = true # allows terraform destroy
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  role_name           = "${local.project_name}-github-deploy"
  github_repository   = local.github_repository
  ecr_repository_arns = [module.registry.repository_arn]
}

module "database" {
  source = "../../modules/database"

  identifier           = "${local.name_prefix}-db"
  vpc_id               = module.network.vpc_id
  db_subnet_group_name = module.network.database_subnet_group_name

  db_name  = "libris"
  username = "libris"

  # Easy to destroy. In a real production, invert both.
  deletion_protection = false
  skip_final_snapshot = true
}