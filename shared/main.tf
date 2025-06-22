provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  use_oidc        = true
}

# initial resource group, storage account and storage container for state are all created manually
data "azurerm_resource_group" "rg_shared" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

module "key_vault" {
  source = "../modules/key_vault"

  resource_group_name = data.azurerm_resource_group.rg_shared.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  location            = var.location
  environment         = null
}

resource "azurerm_key_vault_secret" "ghcr_PAT" {
  name         = "github-pat"
  value        = var.github_pat
  key_vault_id = module.key_vault.key_vault_id
}