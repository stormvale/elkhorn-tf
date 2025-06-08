resource "azurerm_storage_account" "storage" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  min_tls_version                 = "TLS1_2"
  access_tier                     = "Hot"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  account_kind                    = "StorageV2"
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type

  sas_policy {
    expiration_period = "01.12:00:00"
  }

  tags = merge(
    var.tags,
    tomap({
      environment = var.environment
      managedby   = "terraform"
    })
  )

  # enable soft-delete (CKV2_AZURE_38)
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}