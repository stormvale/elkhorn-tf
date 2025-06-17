provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  use_oidc        = true
}

# the service principal for the github application used to run actions
data "azuread_service_principal" "github_actions_sp" {
  client_id = var.client_id
}

# initial resource group, storage account and storage container for state are all created manually
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                            = "kv-${local.name_suffix}" # kv-elkhorn-wus2
  location                        = var.location
  resource_group_name             = data.azurerm_resource_group.rg.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  soft_delete_retention_days      = 7
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true

  # keep purge protection disabled. it complicates things and prevents
  # you from deleting the keyvault for like 90 days or something.
  purge_protection_enabled = false

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = ["10.0.2.0/23"] # "cae_subnet" CIRD block
  }

  # access_policy { ... }

  tags = {
    environment = "shared"
    managedby   = "terraform"
  }
}

resource "azurerm_key_vault_secret" "ghcr_PAT" {
  name         = "github-pat"
  value        = var.github_pat
  key_vault_id = azurerm_key_vault.vault.id
}