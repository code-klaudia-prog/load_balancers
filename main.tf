# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "example-resources"
  location = "West Europe"
}

# Call the modules
module "network" {
  source            = "./modules/network"
}

module "database" {
  source            = "./modules/database"
}

module "app_services" {
  source            = "./modules/app_services"
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name      = "example-resources"
  location  = "West Europe"
}

# --- Módulo de Rede ---
module "network" {
  source              = "./modules/network"
}

# --- Módulo de Banco de Dados ---
module "database" {
  source               = "./modules/database"
}

# --- Módulo de App Services e Application Gateway ---
module "app_services" {
  source                = "./modules/app_services"
}
