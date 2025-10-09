provider "aws" {
  region = "us-east-1" 
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" # Use a versão mais recente e estável

  # VPC CIDR Block
  name = "vpc-avancada-tf"
  cidr = "10.0.0.0/16"

  # Multiple AZ Distribution
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  
  # CIDRs for Public Subnets
  public_subnets  = ["10.0.1.0/24", "10.0.3.0/24"]
  
  # CIDRs for Private Subnets
  private_subnets = ["10.0.2.0/24", "10.0.4.0/24"]

  # Gateways Configuration
  enable_nat_gateway     = true  
  single_nat_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true
  tags = {
    Terraform   = "true"
    Ambiente    = "Desenvolvimento"
    Projeto     = "VPC Avancada"
  }
}

# Testing Connectivity

# Find the most recent ami (Amazon Linux 2)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create a Key Pair for SSH access to access the EC2 instance through Bastion Host
# resource "aws_key_pair" "deployer" {
#  key_name   = "private-instance-key"
#  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4" # Replace
#}

# Create a Security Group for the private EC2 instance

resource "aws_security_group" "private_sg" {
  name        = "private-instance-sg"
  description = "Security group for private instances"
  vpc_id      = module.vpc.vpc_id

  # Inbound Rule - Allows SSH conection from the outside into the VPC through the Bastion Host
  ingress {
    description = "Allow SSH from within VPC CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Allows SSH acces by any resource within the VPC (10.0.0.0/16)
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # Outbound Rule -This is what allows the NAT Gateway test
  # It allows all outbound traffic (routed trhough the NAT Gateway)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PrivateSG"
  }
}

resource "aws_instance" "private_test_instance" {
  ami           = "ami-052064a798f08f0d3"
  instance_type = "t3.micro"
  # key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  # Desliga a atribuição automática de IP público (característica da subnet privada)
  associate_public_ip_address = true

  tags = {
    Name = "Private Test Instance via NAT GW"
  }
}
