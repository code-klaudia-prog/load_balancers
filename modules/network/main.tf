# Create a virtual network within the resource group
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  resource_group_name = "example-resources"
  location            = "West Europe"
  address_space       = ["10.0.0.0/16"]
}
