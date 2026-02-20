# Root Module - PBL/main.tf

# Get list of availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# ======================
# IAM Resources
# ======================

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_instance_role" {
  name = "${var.name}-ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-ec2-instance-role"
    },
  )
}

# IAM Policy for EC2 instances
resource "aws_iam_policy" "ec2_instance_policy" {
  name        = "${var.name}-ec2-instance-policy"
  description = "Policy for EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "s3:Get*",
          "s3:List*",
          "ssm:GetParameter*",
          "ssm:DescribeParameters"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-ec2-instance-policy"
    },
  )
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ec2_instance_policy_attach" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_instance_policy.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-ec2-instance-profile"
    },
  )
}

# ======================
# Network Module
# ======================
module "network" {
  source = "./modules/network"

  name                                = var.name
  vpc_cidr                            = var.vpc_cidr
  enable_dns_support                  = var.enable_dns_support
  enable_dns_hostnames                = var.enable_dns_hostnames
  preferred_number_of_public_subnets  = var.preferred_number_of_public_subnets
  preferred_number_of_private_subnets = var.preferred_number_of_private_subnets
  tags                                = var.tags
  azs                                 = data.aws_availability_zones.available.names
}

# ======================
# Security Module
# ======================
module "security" {
  source = "./modules/security"

  name   = var.name
  vpc_id = module.network.vpc_id
  tags   = var.tags
}

# ======================
# Compute Module
# ======================
module "compute" {
  source = "./modules/compute"

  name                 = var.name
  amis_map             = var.amis
  region               = var.region
  instance_type        = var.instance_type
  key_name             = var.keypair
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name # Fixed reference
  bastion_sg_id        = module.security.bastion_sg_id
  nginx_sg_id          = module.security.nginx_sg_id
  webserver_sg_id      = module.security.webserver_sg_id
  public_subnet_ids    = module.network.public_subnet_ids
  private_subnet_ids   = module.network.private_subnet_ids
  tags                 = var.tags
  azs                  = data.aws_availability_zones.available.names
}

# ======================
# ALB Module
# ======================
# module "alb" {
#   source = "./modules/alb"

#   name               = var.name
#   ext_alb_sg_id      = module.security.ext_alb_sg_id
#   int_alb_sg_id      = module.security.int_alb_sg_id
#   public_subnet_ids  = module.network.public_subnet_ids
#   private_subnet_ids = module.network.private_subnet_ids
#   vpc_id             = module.network.vpc_id
#   tags               = var.tags
# }

# ======================
# Autoscaling Module
# ======================
module "autoscaling" {
  source = "./modules/autoscaling"

  name                         = var.name
  environment                  = var.environment
  public_subnet_ids            = module.network.public_subnet_ids
  private_subnet_ids           = module.network.private_subnet_ids
  bastion_launch_template_id   = module.compute.bastion_launch_template_id
  nginx_launch_template_id     = module.compute.nginx_launch_template_id
  wordpress_launch_template_id = module.compute.wordpress_launch_template_id
  tooling_launch_template_id   = module.compute.tooling_launch_template_id
  nginx_target_group_arns      = [module.alb.nginx_target_group_arn]
  wordpress_target_group_arns  = [module.alb.wordpress_target_group_arn]
  tooling_target_group_arns    = [module.alb.tooling_target_group_arn]
  create_wordpress_asg         = var.create_wordpress_asg
  create_tooling_asg           = var.create_tooling_asg
  tags                         = var.tags
}

# ======================
# EFS Module
# ======================
module "efs" {
  source = "./modules/efs"

  name               = var.name
  private_subnet_ids = module.network.private_subnet_ids
  datalayer_sg_id    = module.security.datalayer_sg_id
  tags               = var.tags
}

# ======================
# RDS Module
# ======================
module "rds" {
  source = "./modules/rds"

  name               = var.name
  private_subnet_ids = module.network.private_subnet_ids
  datalayer_sg_id    = module.security.datalayer_sg_id
  db_username        = var.master-username
  db_password        = var.master-password
  db_name            = var.db_name
  tags               = var.tags
}