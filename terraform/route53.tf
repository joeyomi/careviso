locals {
  domain_name = var.route53_zone_name == null ? "" : (var.alb_subdomain == null ? (var.route53_zone_name) : "${var.alb_subdomain}.${var.route53_zone_name}")
}

#------------------------------------------------------------------------------
# Route53 Hosted Zone
#------------------------------------------------------------------------------
data "aws_route53_zone" "this" {
  count = var.create_route53_zone ? 0 : 1
  name  = var.route53_zone_name
}

resource "aws_route53_zone" "this" {
  count = var.create_route53_zone ? 1 : 0

  name = var.route53_zone_name
  tags = merge({
    Name = "${replace(var.route53_zone_name, ".", "-")}-zone"
  }, local.tags)
}
