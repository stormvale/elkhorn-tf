resource "azurerm_storage_account" "storage" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = var.account_tier
  account_kind                    = "StorageV2"
  account_replication_type        = var.replication_type
  min_tls_version                 = "TLS1_2"
  access_tier                     = "Hot"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false # see CKV2_AZURE_41

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