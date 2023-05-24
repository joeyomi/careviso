module "tls_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${local.name}-vpc-tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [module.vpc.vpc_cidr_block, ]
  ingress_rules       = ["https-443-tcp", ]

  egress_rules = ["all-all"]

  tags = local.tags
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 4.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.tls_sg.security_group_id, ]

  endpoints = {
    s3 = {
      service    = "s3"
      create     = true
      subnet_ids = module.vpc.private_subnets
      tags       = { Name = "s3-vpc-endpoint" }
    },
    sns = {
      service             = "sns"
      create              = true
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "sns-vpc-endpoint" }
    },
    lambda = {
      service             = "lambda"
      create              = true
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "lambda-vpc-endpoint" }
    },
    kms = {
      service             = "kms"
      create              = true
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "kms-vpc-endpoint" }
    },
    secretsmanager = {
      service             = "secretsmanager"
      create              = true
      private_dns_enabled = true
      subnet_ids          = module.vpc.database_subnets //distinct(concat(module.vpc.private_subnets, module.vpc.database_subnets))
      tags                = { Name = "secretsmanager-vpc-endpoint" }
    },
  }

  tags = merge(local.tags, {
    Endpoint = "true"
  })
}


# DATA
data "aws_iam_policy_document" "generic_endpoint_deny_policy" {
  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpc"

      values = [module.vpc.vpc_id]
    }
  }
}

data "aws_iam_policy_document" "generic_endpoint_allow_policy" {
  statement {
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpc"

      values = [module.vpc.vpc_id]
    }
  }
}
