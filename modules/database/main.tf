# --- Databse Module ---
module "database" {
  source               = "./modules/database"
  resource_group_name  = "example-resources"
  location             = "West Europe"
  vnet_id              = module.network.vnet_id
  database_subnet_id   = module.network.database_subnet_id
  postgres_server_name = "meu-db-server"
  postgres_db_name     = "meu-db-app"
}