
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
  # is_virtual_network_filter_enabled     = true
  public_network_access_enabled = true # default = true
  # ip_range_filter = ["13.91.105.215", "4.210.172.107", "13.88.56.148", "40.91.218.243"] # Azure Portal
  tags = var.tags

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

  identity { type = "SystemAssigned" }

  # any subnet id's that are allowed to access this account
  dynamic "virtual_network_rule" {
    for_each = var.allowed_subnet_ids != null ? var.allowed_subnet_ids : []
    content {
      id                                   = virtual_network_rule.value
      ignore_missing_vnet_service_endpoint = true
    }
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  for_each = var.cosmos_databases

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.account.name

  autoscale_settings {
    max_throughput = try(each.value.throughput, null)
  }
}

locals {
  # flatten the nested structure of containers
  cosmos_containers = flatten([
    for db_name, db in var.cosmos_databases : [
      for container_name, container in db.containers : {
        db_name             = db_name
        container_name      = container_name
        partition_key_paths = container.partition_key_paths
        throughput          = try(container.throughput, null)
      }
    ]
  ])

  # convert to a map to use in for_each
  cosmos_container_map = {
    for item in local.cosmos_containers :
    "${item.db_name}.${item.container_name}" => item
  }
}

resource "azurerm_cosmosdb_sql_container" "container" {
  for_each = local.cosmos_container_map

  name                  = each.value.container_name
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.account.name
  database_name         = each.value.db_name
  partition_key_paths   = each.value.partition_key_paths
  partition_key_version = 2
}