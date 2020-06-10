provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "maibeer"
  location = "brazilsouth"
}


resource "azurerm_cosmosdb_account" "default" {
  name                = "cosmos-maibeer-prototype"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = false

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }

}

resource "azurerm_cosmosdb_mongo_database" "default" {
  name                = "maibeer"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.default.name
  throughput          = 400
}

resource "azurerm_cosmosdb_mongo_collection" "questions" {
  name                = "questions"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.default.name
  database_name       = azurerm_cosmosdb_mongo_database.default.name

  default_ttl_seconds = "0"
  shard_key           = "product"
  throughput          = 400
}

resource "azurerm_cosmosdb_mongo_collection" "answers" {
  name                = "answers"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.default.name
  database_name       = azurerm_cosmosdb_mongo_database.default.name

  default_ttl_seconds = "0"
  shard_key           = "address.zipcode"
  throughput          = 400

  depends_on = [
    azurerm_cosmosdb_mongo_collection.answers
  ]

}

resource "azurerm_key_vault" "prototype" {
  name                        = "kv-maibeer-prototype"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = true
  purge_protection_enabled    = false

  sku_name = "standard"

  # access_policy {
  #   tenant_id = data.azurerm_client_config.current.tenant_id
  #   object_id = data.azurerm_client_config.current.object_id

  #   key_permissions = [
  #     "get",
  #   ]
  # }

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

}

output "cosmosdb_connection_strings" {
  value = azurerm_cosmosdb_account.default.connection_strings
}

output "vault_uri" {
  value = azurerm_key_vault.prototype.vault_uri
}