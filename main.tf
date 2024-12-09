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

resource "aws_vpc" "tf_class_vpc" {
  cidr_block = "10.0.0.0/16"
 
  tags = {
    Name = "tf_class_vpc"
  }
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.blog.id]
  subnet_id = aws_subnet.public_subnet.id

  tags = {
    Name = "tf_class_HelloWorld"
  }
}

resource "aws_security_group" "blog" {
  name = "blog"
  description = "allow http/s in and all out"
  
  vpc_id = aws_vpc.tf_class_vpc.id

  tags = {
    Name = "tf_class_sg"
  }
}

resource "aws_security_group_rule" "blog_http_in" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  
  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group_rule" "blog_https_in" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  
  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group_rule" "blog_all_out" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  
  security_group_id = aws_security_group.blog.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "tf_class_subnet"
  }
}