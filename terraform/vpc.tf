#------------------------------------------------------------------------------
# VPC Module
#------------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = "${local.name}-vpc"
  cidr = "10.0.0.0/16"

  azs              = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  private_subnet_names  = []
  public_subnet_names   = []
  database_subnet_names = []

  create_database_subnet_group = true
  database_subnet_group_name   = "${local.name}-db-subnet-group"

  manage_default_network_acl = true
  default_network_acl_tags   = { Name = "${local.name}-default" }

  manage_default_route_table = true
  default_route_table_tags   = { Name = "${local.name}-default" }

  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_vpn_gateway  = false
  enable_dhcp_options = false

  # VPC Flow Logs
  flow_log_destination_type = "s3"
  flow_log_destination_arn  = module.vpc_flow_logs_s3.s3_bucket_arn
  flow_log_file_format      = "parquet"

  vpc_flow_log_tags = local.tags

  private_subnet_tags = {
    "scope" = "private"
  }

  public_subnet_tags = {
    "scope" = "public"
  }

  database_subnet_tags = {
    "scope" = "database"
  }

  tags = local.tags
}
