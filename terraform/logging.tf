#------------------------------------------------------------------------------
# ALB Access Logs
#------------------------------------------------------------------------------
module "alb_access_logs_s3" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = "${local.name}-alb-access-logs-${random_pet.this.id}"

  control_object_ownership = true

  attach_elb_log_delivery_policy = true
  attach_lb_log_delivery_policy  = true

  force_destroy = true

  tags = local.tags
}


#------------------------------------------------------------------------------
# VPC Flow Logs
#------------------------------------------------------------------------------
module "vpc_flow_logs_s3" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket        = "${local.name}-vpc-flow-logs-${random_pet.this.id}"
  attach_policy = true
  policy        = data.aws_iam_policy_document.vpc_flow_log_s3.json
  force_destroy = true

  tags = local.tags
}

data "aws_iam_policy_document" "vpc_flow_log_s3" {
  statement {
    sid = "AWSLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["arn:aws:s3:::${local.name}-vpc-flow-logs-${random_pet.this.id}/*"]
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]

    resources = ["arn:aws:s3:::${local.name}-vpc-flow-logs-${random_pet.this.id}"]
  }
}
