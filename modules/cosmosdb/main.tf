
resource "azurerm_cosmosdb_account" "account" {
  name                                  = "cosno-${local.name_suffix}"
  location                              = var.location
  resource_group_name                   = var.resource_group_name
  default_identity_type                 = "FirstPartyIdentity" #join("=", ["UserAssignedIdentity", var.user_assigned_identity_id])
  minimal_tls_version                   = "Tls12"
  offer_type                            = "Standard"
  kind                                  = "GlobalDocumentDB"
  free_tier_enabled                     = true
  network_acl_bypass_for_azure_services = true
  tags                                  = var.tags

  backup {
    type = "Continuous"
    tier = "Continuous7Days"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  # Azure Portal Middleware IP addresses
  ip_range_filter = ["13.91.105.215", "4.210.172.107", "13.88.56.148", "40.91.218.243"]

  identity {
    type = "SystemAssigned"
  }
}


# To take advantage of the free tier during development, we will use a single database
# with containers for each service, instead of the preferred "database per service" approach.
resource "azurerm_cosmosdb_sql_database" "db" {
  # for_each            = var.databases

  name                = "elkhornDb" # each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.account.name
  throughput          = 1000 # Free tier max = 1000 RU/s per account
}

resource "azurerm_cosmosdb_sql_container" "container" {
  for_each = var.databases

  name                  = each.value.container_name
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.account.name
  database_name         = azurerm_cosmosdb_sql_database.db.name # azurerm_cosmosdb_sql_database.db[each.key].name
  partition_key_paths   = each.value.partition_key_paths
  partition_key_version = 2
}