# main.tf

# 1. Configuração do Provedor e Requisitos do Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configuração do Provedor AWS
# **ATENÇÃO:** Altere a 'region' para a sua preferida (ex: 'eu-west-1')
provider "aws" {
  region = "eu-west-1"
}

# 2. Descoberta das Availability Zones
# Usamos um data source para garantir que a região tenha pelo menos 2 AZs disponíveis.
data "aws_availability_zones" "available" {
  # Filtra para ter pelo menos 2 AZs (o número de subnets em pares que você pediu)
  state = "available"
}

# 3. Criação da VPC Avançada com o Módulo
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" # Use a versão mais recente e estável

  # Requisito 1: VPC CIDR Block
  name = "vpc-avancada-tf"
  cidr = "10.0.0.0/16"

  # Requisito 2: Distribuição em Múltiplas AZs
  # Usa as duas primeiras AZs disponíveis
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  
  # Requisito 3: CIDRs Específicos para Subnets Públicas
  # A ordem dos CIDRs corresponde à ordem das AZs em 'azs'
  public_subnets  = ["10.0.1.0/24", "10.0.3.0/24"]
  
  # Requisito 3: CIDRs Específicos para Subnets Privadas
  private_subnets = ["10.0.2.0/24", "10.0.4.0/24"]

  # Configuração de Gateways
  enable_nat_gateway     = true          # Cria um NAT Gateway em cada AZ (melhor para redundância)
  single_nat_gateway     = false         # Garante que cria um NAT GW por AZ (por isso é 'false')
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # Roteamento entre Subnets Privadas:
  # O roteamento interno (entre subnets privadas dentro da mesma VPC) é
  # automaticamente gerado pela AWS através da 'Main Route Table' da VPC.
  # O módulo cuida de associar as subnets privadas a tabelas de rotas que
  # não têm rota para o IGW (Internet Gateway), mas mantêm a rota para o CIDR
  # da própria VPC (10.0.0.0/16), permitindo a comunicação interna.

  tags = {
    Terraform   = "true"
    Ambiente    = "Desenvolvimento"
    Projeto     = "VPC Avancada"
  }
}

# 4. Outputs para Verificação
# Estes outputs ajudam a verificar os requisitos 2, 3 e 4.
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
