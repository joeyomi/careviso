#------------------------------------------------------------------------------
# All Alerts are configured to use Slack
#------------------------------------------------------------------------------
locals {
  slack_webhook_url = var.slack_webhook_url != null ? var.slack_webhook_url : data.aws_secretsmanager_secret_version.slack_webhook_url[0].secret_string
}

#------------------------------------------------------------------------------
# Slack Notifications (Alert Channel)
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "slack_webhook_url" {
  count = var.slack_webhook_url == null ? 1 : 0

  name = "${local.name}-slack-webhook-${random_pet.this.id}"
  replica {
    region = "us-west-2"
  }
  tags = local.tags
}

# Secrets should be kept out of the VCS.
# Set the Secret on the Console or with the CLI, or pass it directly as a variable (preferrably as an environment variable: `export TF_VAR_slack_webhook_url="https://hooks.slack.com/services/XXXXXXXXXX"`)
# It will still be stored in terraform state but other controls are in place (IAM Controls, Encryption with KMS etc.).
data "aws_secretsmanager_secret_version" "slack_webhook_url" {
  count     = var.slack_webhook_url == null ? 1 : 0
  secret_id = aws_secretsmanager_secret.slack_webhook_url[0].id
}

module "notify_slack" {
  source  = "terraform-aws-modules/notify-slack/aws"
  version = "~> 6.0"

  sns_topic_name = "slack-topic-${local.name}"

  lambda_function_name = "notify-slack-${local.name}"

  slack_webhook_url = local.slack_webhook_url
  slack_channel     = "software"
  slack_username    = "cloudwatch-${local.name}"

  lambda_description = "Lambda function which sends notifications to Slack"
  log_events         = true

  tags = {
    Name = "cloudwatch-alerts-to-slack"
  }
}

#------------------------------------------------------------------------------
# ALB
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_latency_high" {
  alarm_name          = "${local.name}-alb-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "Latency"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0.5"
  alarm_description   = "Latency has exceeded 0.5 seconds"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]

  dimensions = {
    LoadBalancer = module.alb.lb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_4xx_errors_high" {
  alarm_name          = "${local.name}-alb-4xx-errors-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "4XX error rate has exceeded 10%"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]

  dimensions = {
    LoadBalancer = module.alb.lb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_request_count_high" {
  alarm_name          = "${local.name}-alb-request-count-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "Request count has exceeded 1000"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]

  dimensions = {
    LoadBalancer = module.alb.lb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors_high" {
  alarm_name          = "${local.name}-alb-5xx-errors-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "5XX error rate has exceeded 10%"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]

  dimensions = {
    LoadBalancer = module.alb.lb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_target_response_time_high" {
  alarm_name          = "${local.name}-alb-target-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Target response time has exceeded 1 second"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]

  dimensions = {
    LoadBalancer = module.alb.lb_arn_suffix
  }
}


#------------------------------------------------------------------------------
# ASG
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "autoscaling_group_size" {
  alarm_name          = "${local.name}-asg-group-size"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "GroupSize"
  namespace           = "AWS/AutoScaling"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Auto Scaling Group size is below the desired threshold"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]
  dimensions = {
    AutoScalingGroupName = module.asg.autoscaling_group_name
  }
}

resource "aws_cloudwatch_metric_alarm" "autoscaling_cpu_utilization" {
  alarm_name          = "${local.name}-asg-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Average CPU utilization exceeds 80%"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]
  dimensions = {
    AutoScalingGroupName = module.asg.autoscaling_group_name
  }
}

resource "aws_cloudwatch_metric_alarm" "autoscaling_network_in" {
  alarm_name          = "${local.name}-asg-network-in"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "100000000"
  alarm_description   = "Network traffic in exceeds 100 MB/s"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]
  dimensions = {
    AutoScalingGroupName = module.asg.autoscaling_group_name
  }
}

resource "aws_cloudwatch_metric_alarm" "autoscaling_network_out" {
  alarm_name          = "${local.name}-asg-network-out"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "100000000"
  alarm_description   = "Network traffic out exceeds 100 MB/s"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]
  dimensions = {
    AutoScalingGroupName = module.asg.autoscaling_group_name
  }
}

resource "aws_cloudwatch_metric_alarm" "autoscaling_disk_read_io" {
  alarm_name          = "${local.name}-asg-disk-io"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "DiskReadBytes"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "100000000"
  alarm_description   = "Disk read bytes exceeds 100 MB/s"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]
  dimensions = {
    AutoScalingGroupName = module.asg.autoscaling_group_name
  }
}

resource "aws_cloudwatch_metric_alarm" "autoscaling_disk_write_io" {
  alarm_name          = "${local.name}-asg-disk-write-io"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "DiskWriteBytes"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "100000000"
  alarm_description   = "Disk write bytes exceeds 100 MB/s"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]
  dimensions = {
    AutoScalingGroupName = module.asg.autoscaling_group_name
  }
}


#------------------------------------------------------------------------------
# RDS
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "aurora_cpu_high" {
  alarm_name          = "${local.name}-aurora-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "CPU utilization has exceeded 80%"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]

  dimensions = {
    DBInstanceIdentifier = module.aurora.cluster_id
  }
}

resource "aws_cloudwatch_metric_alarm" "aurora_free_storage_low" {
  alarm_name          = "${local.name}-aurora-free-storage-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "3600"
  statistic           = "Minimum"
  threshold           = "5000000000"
  alarm_description   = "Free storage space has fallen below 5 GB"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]

  dimensions = {
    DBInstanceIdentifier = module.aurora.cluster_id
  }
}

resource "aws_cloudwatch_metric_alarm" "aurora_connections_high" {
  alarm_name          = "${local.name}-aurora-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "100"
  alarm_description   = "Database connections have exceeded 100"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]

  dimensions = {
    DBInstanceIdentifier = module.aurora.cluster_id
  }
}

resource "aws_cloudwatch_metric_alarm" "aurora_latency_high" {
  alarm_name          = "${local.name}-aurora-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "DatabaseQueryLatency"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "0.5"
  alarm_description   = "Read/Write Latency has exceeded 0.5 seconds"
  alarm_actions       = [module.notify_slack.slack_topic_arn, ]

  dimensions = {
    DBInstanceIdentifier = module.aurora.cluster_id
  }
}
