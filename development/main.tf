provider "azurerm" {
  features {}
  use_oidc = true
}

module "naming" {
  source  = "Azure/naming/azurerm"
  suffix = [ "dev" ]
}

# the resource group for dev environment
resource "azurerm_resource_group" "rg" {
  name     = module.naming.resource_group.name
  location = var.location
  tags     = local.tags
}

# a storage account for dev environment
module "storage" {
  source = "../.github/workflows/modules/storage_account"

  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  name = module.naming.storage_account.name
  environment = "development"
}