terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# Find the latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group
resource "aws_security_group" "lab" {
  name        = "sre-lab-sg"
  description = "SRE lab SSH and app access"

  ingress {
    description = "SSH from my laptop"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["223.233.86.168/32"]
  }

  ingress {
    description = "Demo application"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "sre-lab-sg"
    Project = "sre-lab"
  }
}

# EC2 Instance
resource "aws_instance" "lab" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = "new-key"
  vpc_security_group_ids      = [aws_security_group.lab.id]
  associate_public_ip_address = true

  user_data = <<-EOT
    #!/bin/bash
    set -eux

    apt-get update -y
    apt-get install -y docker.io curl

    systemctl enable --now docker
    usermod -aG docker ubuntu
  EOT

  tags = {
    Name    = "sre-lab-ec2"
    Project = "sre-lab"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }
}

# Output EC2 Public IP
output "public_ip" {
  value = aws_instance.lab.public_ip
}
