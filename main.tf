data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Name = "tf_class_dev_vpc"
    Terraform = "true"
    Environment = "dev"
  }
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "8.0.0"
  
  name = "blog"
  min_size = 1
  max_size = 2

  vpc_zone_identifier = module.blog_vpc.public_subnets
  #target_group_arns = module.blog_alb.target_group_arns
  security_groups = [module.blog_vpc.default_security_group_id]

  image_id           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  tags = {
    Name = "tf_class_HelloWorld"
  }
}

module "blog_alb" {
  source = "terraform-aws-modules/alb/aws"
  name    = "blog-alb"
  load_balancer_type = "application"

  vpc_id  = module.blog_vpc.vpc_id
  subnets = module.blog_vpc.public_subnets
  security_groups = [module.blog_vpc.default_security_group_id]

  target_groups = {
    tg = {
      name_prefix      = "blog-"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      target_id        = aws_instance.blog.id  
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "tg"
      }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "tf_class"
  }
}