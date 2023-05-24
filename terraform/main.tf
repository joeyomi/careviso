#------------------------------------------------------------------------------
# Locals
#------------------------------------------------------------------------------
locals {
  region           = var.region
  environment      = var.environment
  prefix           = var.prefix
  name             = "${var.prefix}-${var.environment}"
  name_pascal_case = replace(title(replace(local.name, "-", " ")), " ", "")

  tags = {
    environment = var.environment,
    ManagedBy   = "Terraform"
  }
}

#------------------------------------------------------------------------------
# Data
#------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}
data "aws_availability_zones" "available" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_elb_service_account" "main" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }
}


#------------------------------------------------------------------------------
# Supporting Resources
#------------------------------------------------------------------------------
resource "random_pet" "this" {
  length = 2
}
