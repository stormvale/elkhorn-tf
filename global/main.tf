
provider "azurerm" {
  features {}
  use_oidc = true
}

# The initial global resource group, storage account and storage container
# need to be created outside of terraform. Need to match the configured
# azurerm provider.

data "azurerm_resource_group" "rg" {
  name = "rg-elkhorn-wus2"
}

data "azurerm_storage_account" "storage" {
  name                = "stoelkhornu3g3pw"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_storage_container" "tfstate" {
  name                 = "tfstate"
  storage_account_name = data.azurerm_storage_account.storage.name
}

###################################################################

# resource "azurerm_container_registry" "acr" {
#   name                = replace("acr-${local.name_suffix}", "-", "") # acrelkhornwus2
#   resource_group_name = data.azurerm_resource_group.rg.name
#   location            = data.azurerm_resource_group.rg.location
#   sku                 = "Basic"
#   admin_enabled       = false
# }