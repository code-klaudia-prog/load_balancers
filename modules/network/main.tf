# --- Módulo de Rede ---
module "network" {
  source               = "./modules/network"
  resource_group_name  = "example-resources"
  location             = "West Europe"
  vnet_name            = "meu-vnet-producao"
  vnet_address_space   = ["10.0.0.0/16"]
  frontend_subnet_name = "frontend-subnet"
  backend_subnet_name  = "backend-subnet"
  database_subnet_name = "database-subnet"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  resource_group_name = "example-resources"
  location            = "West Europe"
  address_space       = ["10.0.0.0/16"]
}