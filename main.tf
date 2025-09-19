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

module "network" {
  source  = "Azure/network/azurerm"
  version = "5.3.0"
  # insert the 2 required variables here
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  resource_group_name = "example-resources"
  location            = "West Europe"
  address_space       = ["10.0.0.0/16"]
}
