# --- App Services e Application Gateway Module ---
module "app_services" {
  source               = "source = "minha-empresa/database/azurerm"
  resource_group_name   = "example-resources"
  location              = "West Europe"
  vnet_id               = module.network.vnet_id
  frontend_subnet_id    = module.network.frontend_subnet_id
  backend_subnet_id     = module.network.backend_subnet_id
  app_gateway_subnet_id = module.network.app_gateway_subnet_id
  database_server_name  = module.database.postgres_server_name
}
