
resource "azurerm_key_vault" "vault" {
  name                            = "kv-${local.name_suffix}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = var.tenant_id
  sku_name                        = "standard"
  soft_delete_retention_days      = 7
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true
  tags                            = var.tags

  # keep purge protection disabled. it complicates things and prevents
  # you from deleting the keyvault for like 90 days or something.
  purge_protection_enabled = false

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }
}