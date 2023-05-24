module "bastion" {
  source  = "cloudposse/ec2-bastion-server/aws"
  version = "0.30.1"

  enabled       = true
  name          = "${local.name}-bastion"
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  security_groups = compact(concat([module.vpc.default_vpc_default_security_group_id]))
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  tags = local.tags
}
