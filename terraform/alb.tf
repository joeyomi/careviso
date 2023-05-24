#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${local.name}-alb-sg"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for ${local.name} ALB"

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  tags = merge({
    Name = "${local.name}-alb-sg"
  }, local.tags)
}

#------------------------------------------------------------------------------
# Application Load Balancer
#------------------------------------------------------------------------------
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "${local.name}-alb"

  load_balancer_type = "application"
  internal           = false

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.alb_sg.security_group_id]

  access_logs = {
    enabled = true
    bucket  = module.alb_access_logs_s3.s3_bucket_id
  }

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    },
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = var.route53_zone_name != null ? module.acm[0].acm_certificate_arn : null
      action_type        = "forward"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name             = "${local.name}-tg"
      backend_protocol = "HTTP"
      backend_port     = var.backend_port
      target_type      = "instance"
      health_check = {
        path    = "/"
        port    = var.backend_port
        matcher = "200-299"
      }
    },
  ]
}

#------------------------------------------------------------------------------
# Route 53 (DNS Records)
#------------------------------------------------------------------------------
resource "aws_route53_record" "www" {
  count = var.route53_zone_name != null ? 1 : 0

  zone_id = var.create_route53_zone ? aws_route53_zone.this[0].id : data.aws_route53_zone.this[0].id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = module.alb.lb_dns_name
    zone_id                = module.alb.lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_dot" {
  count = var.route53_zone_name != null ? 1 : 0

  zone_id = var.create_route53_zone ? aws_route53_zone.this[0].id : data.aws_route53_zone.this[0].id
  name    = "www.${local.domain_name}"
  type    = "A"

  alias {
    name                   = module.alb.lb_dns_name
    zone_id                = module.alb.lb_zone_id
    evaluate_target_health = false
  }
}

#------------------------------------------------------------------------------
# ACM (TLS Certs)
#------------------------------------------------------------------------------
module "acm" {
  count = var.route53_zone_name != null ? 1 : 0

  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name = local.domain_name
  zone_id     = var.create_route53_zone ? aws_route53_zone.this[0].id : data.aws_route53_zone.this[0].id

  subject_alternative_names = [
    "www.${local.domain_name}",
  ]

  wait_for_validation = true

  tags = merge({
    Name = local.domain_name
  }, local.tags)
}
