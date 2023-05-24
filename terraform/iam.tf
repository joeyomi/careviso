#------------------------------------------------------------------------------
# EC2 - Secrets Manager
#------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_execution" {
  name               = "${local.name}-ec2-execution"
  assume_role_policy = data.aws_iam_policy_document.ec2_execution.json
  tags               = local.tags
}

data "aws_iam_policy_document" "ec2_execution" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy_attachment" "ec2_execution" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
  ])

  name       = "${local.name}-ec2-execution"
  roles      = [aws_iam_role.ec2_execution.name]
  policy_arn = each.value
}

resource "aws_iam_policy" "secrets_manager_read_policy" {
  name   = "EC2ExecutionReadSecretsManager${local.name_pascal_case}"
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "secretsmanager:GetSecretValue"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_policy_attachment" "secret_manager_read" {
  name       = "${local.name}-secrets-manager-ec2-execution-policy"
  roles      = [aws_iam_role.ec2_execution.name]
  policy_arn = aws_iam_policy.secrets_manager_read_policy.arn
}
