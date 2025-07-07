resource "azurerm_storage_account" "storage" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  min_tls_version                 = "TLS1_2"
  access_tier                     = "Hot"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  account_kind                    = "StorageV2"
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  tags                            = var.tags

  sas_policy {
    expiration_period = "02.00:00:00" # dd.HH.mm.ss
  }

  # see also "azurerm_storage_account_network_rules"
  network_rules {
    default_action = "Deny"
    bypass         = ["Logging", "Metrics", "AzureServices"]
    #virtual_network_subnet_ids = var.subnet_ids
  }

  # enable soft-delete (CKV2_AZURE_38)
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

# each web app gets a storage container
resource "azurerm_storage_container" "containers" {
  for_each = var.containers

  name                  = each.value
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}