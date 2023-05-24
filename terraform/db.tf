locals {
  db_instance_class  = "db.serverless"
  rds_engine_version = "15.2"

  db_username = random_pet.user.id // using random here due to secrets taking at least 7 days before fully deleting from account
  db_password = random_password.password.result
}

#------------------------------------------------------------------------------
# Secrets - DB user passwords
#------------------------------------------------------------------------------
resource "random_pet" "user" {
  length    = 2
  separator = "_"
}

resource "random_password" "password" {
  length           = 40
  special          = true
  min_special      = 5
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

# Secrets
data "aws_kms_alias" "secretsmanager" {
  name = "alias/aws/secretsmanager"
}

resource "aws_secretsmanager_secret" "aurora_credentials" {
  name        = "db-pass-${local.db_username}"
  description = "Database superuser, ${local.db_username}, databse connection values"
  kms_key_id  = data.aws_kms_alias.secretsmanager.id
  tags        = local.tags
}

# This will be reset by the Configured Secret Rotation on provisioning.
resource "aws_secretsmanager_secret_version" "aurora_credentials" {
  secret_id = aws_secretsmanager_secret.aurora_credentials.id
  secret_string = jsonencode(
    {
      username = local.db_username
      password = local.db_password
      engine   = "aurora-postgresql"
      host     = module.aurora.cluster_endpoint
    }
  )
}

# DB Secret Rotation
resource "aws_secretsmanager_secret_rotation" "rotation" {
  depends_on = [
    aws_secretsmanager_secret_version.aurora_credentials,
  ]

  secret_id           = aws_secretsmanager_secret.aurora_credentials.id
  rotation_lambda_arn = aws_serverlessapplicationrepository_cloudformation_stack.secret_rotator.outputs.RotationLambdaARN

  rotation_rules {
    automatically_after_days = 14
  }
}

data "aws_serverlessapplicationrepository_application" "secret_rotator" {
  application_id = "arn:aws:serverlessrepo:us-east-1:297356227824:applications/SecretsManagerRDSMySQLRotationSingleUser"
}

resource "aws_serverlessapplicationrepository_cloudformation_stack" "secret_rotator" {
  name             = "Rotate-${replace(local.db_username, "_", "-")}"
  application_id   = data.aws_serverlessapplicationrepository_application.secret_rotator.application_id
  semantic_version = data.aws_serverlessapplicationrepository_application.secret_rotator.semantic_version
  capabilities     = data.aws_serverlessapplicationrepository_application.secret_rotator.required_capabilities

  parameters = {
    endpoint            = "https://secretsmanager.${data.aws_region.current.name}.${data.aws_partition.current.dns_suffix}"
    functionName        = "rotator-${local.db_username}"
    vpcSubnetIds        = element(module.vpc.database_subnets, 0)
    vpcSecurityGroupIds = module.aurora.security_group_id
  }
}

#------------------------------------------------------------------------------
# RDS Proxy
#------------------------------------------------------------------------------
module "rds_proxy" {
  source  = "terraform-aws-modules/rds-proxy/aws"
  version = "~> 2.0"

  create_proxy = true

  name                   = "${local.name}-rds-proxy"
  iam_role_name          = "${local.name}-rds-proxy"
  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [module.rds_proxy_sg.security_group_id]

  db_proxy_endpoints = {
    read_write = {
      name                   = "read-write-endpoint"
      vpc_subnet_ids         = module.vpc.private_subnets
      vpc_security_group_ids = [module.rds_proxy_sg.security_group_id]
      tags                   = local.tags
    },
    read_only = {
      name                   = "read-only-endpoint"
      vpc_subnet_ids         = module.vpc.private_subnets
      vpc_security_group_ids = [module.rds_proxy_sg.security_group_id]
      target_role            = "READ_ONLY"
      tags                   = local.tags
    }
  }

  secrets = {
    (local.db_username) = {
      description = aws_secretsmanager_secret.aurora_credentials.description
      arn         = aws_secretsmanager_secret.aurora_credentials.arn
      kms_key_id  = aws_secretsmanager_secret.aurora_credentials.kms_key_id
    }
  }

  engine_family = "POSTGRESQL"
  debug_logging = true

  # Target Aurora cluster
  target_db_cluster     = true
  db_cluster_identifier = module.aurora.cluster_id

  tags = local.tags
}

module "rds_proxy_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${local.name}-rds-proxy-sg"
  description = "PostgreSQL RDS Proxy security group"
  vpc_id      = module.vpc.vpc_id

  revoke_rules_on_delete = true

  ingress_with_cidr_blocks = [
    {
      description = "Private subnet PostgreSQL access"
      rule        = "postgresql-tcp"
      cidr_blocks = join(",", module.vpc.private_subnets_cidr_blocks)
    }
  ]

  egress_with_cidr_blocks = [
    {
      description = "Database subnet PostgreSQL access"
      rule        = "postgresql-tcp"
      cidr_blocks = join(",", module.vpc.database_subnets_cidr_blocks)
    },
  ]

  tags = local.tags
}

#------------------------------------------------------------------------------
# RDS Aurora Serverless
#------------------------------------------------------------------------------
module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 8.0"

  name              = "${local.name}-db"
  engine            = data.aws_rds_engine_version.postgresql.engine
  engine_version    = data.aws_rds_engine_version.postgresql.version
  engine_mode       = "provisioned"
  storage_encrypted = true

  instance_class = local.db_instance_class
  instances = {
    one = {}
    two = {}
  }
  serverlessv2_scaling_configuration = {
    min_capacity = 2
    max_capacity = 10
  }
  predefined_metric_type = "RDSReaderAverageCPUUtilization"

  //allow_major_version_upgrade=true

  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }

  database_name   = "postgres"
  master_username = local.db_username
  master_password = local.db_password

  iam_database_authentication_enabled = false
  iam_roles                           = {}

  monitoring_interval           = 60
  iam_role_name                 = "${local.name}-rds-monitor"
  iam_role_use_name_prefix      = true
  iam_role_description          = "${local.name} RDS enhanced monitoring IAM role"
  iam_role_path                 = "/serverless/"
  iam_role_max_session_duration = 7200

  apply_immediately   = true
  skip_final_snapshot = true

  db_parameter_group_name         = aws_db_parameter_group.this.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.id
  enabled_cloudwatch_logs_exports = ["postgresql"]

  backup_retention_period = 7
  preferred_backup_window = "02:00-03:00"

  tags = local.tags
}


data "aws_rds_engine_version" "postgresql" {
  engine  = "aurora-postgresql"
  version = local.rds_engine_version
}

resource "aws_db_parameter_group" "this" {
  name        = "${local.name}-aurora-db-postgres15-parameter-group"
  family      = "aurora-postgresql15"
  description = "${local.name}-aurora-db-postgres15-parameter-group"
  tags        = local.tags
}

resource "aws_rds_cluster_parameter_group" "this" {
  name        = "${local.name}-aurora-postgres15-cluster-parameter-group"
  family      = "aurora-postgresql15"
  description = "${local.name}-aurora-postgres15-cluster-parameter-group"
  tags        = local.tags
}


resource "aws_ssm_parameter" "aurora_host" {
  name  = "${local.name}-aurora-host"
  type  = "String"
  value = module.aurora.cluster_endpoint
}

resource "aws_ssm_parameter" "aurora_port" {
  name  = "${local.environment}-aurora-port"
  type  = "String"
  value = 5432
}
