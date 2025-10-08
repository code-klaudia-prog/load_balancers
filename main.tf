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

# Criação da VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" # Use a versão mais recente e estável

  # VPC CIDR Block
  name = "vpc-avancada-tf"
  cidr = "10.0.0.0/16"

  # Distribuição em Múltiplas AZs
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  
  # CIDRs Específicos para Subnets Públicas
  public_subnets  = ["10.0.1.0/24", "10.0.3.0/24"]
  
  # CIDRs Específicos para Subnets Privadas
  private_subnets = ["10.0.2.0/24", "10.0.4.0/24"]

  # Configuração de Gateways
  enable_nat_gateway     = true          # Cria um NAT Gateway em cada AZ (melhor para redundância)
  single_nat_gateway     = false         # Garante que cria um NAT GW por AZ (por isso é 'false')
  enable_dns_hostnames   = true
  enable_dns_support     = true
  tags = {
    Terraform   = "true"
    Ambiente    = "Desenvolvimento"
    Projeto     = "VPC Avancada"
  }
}

# Outputs para Verificação
output "vpc_id" {
  description = "ID da VPC Criada"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "IDs e AZs das Subnets Públicas"
  value       = zipmap(module.vpc.public_subnets_names, module.vpc.public_subnets_azs)
}

output "private_subnets" {
  description = "IDs e AZs das Subnets Privadas"
  value       = zipmap(module.vpc.private_subnets_names, module.vpc.private_subnets_azs)
}

output "public_route_table_routes" {
  description = "Rotas da Tabela Pública (deve ter rota para 0.0.0.0/0 via IGW)"
  value       = module.vpc.public_route_table_routes
}

output "private_route_table_routes" {
  description = "Rotas das Tabelas Privadas (deve ter rota para 0.0.0.0/0 via NAT Gateway)"
  value       = module.vpc.private_route_table_routes
}
