variable "profile" {
  type        = string
  description = "AWS Profile to use (should already exist)."
  default     = "default"
}

variable "region" {
  type        = string
  description = "Default AWS region."
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Current Environment"
}

variable "prefix" {
  type        = string
  description = "Prefix to prepend to resources (for easy identification)."
}



variable "assume_role_arn" {
  type        = string
  description = "AWS role to assume when provisioning resources"
  default     = ""
}

variable "assume_role_external_id" {
  type        = string
  description = "Extenal ID associated with the \"assume_role_arn\"."
  default     = ""
}


variable "route53_zone_name" {
  type        = string
  description = "Route 53 Zone domain name to create ALB record in, no records will be created if this is left empty."
  default     = null
}

variable "create_route53_zone" {
  type        = bool
  description = "Should the Route53 Zone be created, you'll need to add the NS records to your Registrar for ACM certificate validations to pass."
  default     = false
}

variable "alb_subdomain" {
  type        = string
  description = "Subdomain for the ALB, defaults to domain_name if not passed."
  default     = null
}

variable "backend_port" {
  type        = number
  description = "Port ALB directs instance traffic to."
  default     = 80
}

variable "slack_webhook_url" {
  type        = string
  description = "Webhook URL for configurations Slack notifications/ alerts."
  default     = null
}

