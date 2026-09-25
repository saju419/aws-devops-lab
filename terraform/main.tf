terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "saju-terraform-state-834877788713"
    key          = "devops-lab/terraform.tfstate"
    region       = "ap-south-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-south-2"
}


# Find latest Ubuntu 24.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# Security Group
resource "aws_security_group" "devops_lab_sg" {

  name        = "devops-lab-sg"
  description = "Security Group created by Terraform"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# EC2 Instance
resource "aws_instance" "devops_server" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  key_name = aws_key_pair.devops_key.key_name

  vpc_security_group_ids = [
    aws_security_group.devops_lab_sg.id
  ]

  tags = {
    Name = "terraform-devops-server"
  }
}


# Outputs
output "instance_id" {
  value = aws_instance.devops_server.id
}

output "private_ip" {
  value = aws_instance.devops_server.private_ip
}

output "public_ip" {
  value = aws_instance.devops_server.public_ip
}

resource "aws_key_pair" "devops_key" {
  key_name   = "terraform-devops-key"
  public_key = file("${path.module}/devops-key.pub")

  lifecycle {
    ignore_changes = [public_key]
  }
}
