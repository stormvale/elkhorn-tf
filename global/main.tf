
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

data "azurerm_storage_container" "tfstate_global" {
  name                 = "tfstate-global"
  storage_account_name = data.azurerm_storage_account.storage.name
}

###################################################################

resource "azurerm_storage_container" "tfstate_dev" {
  name                  = "tfstate-dev"
  storage_account_name  = data.azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "tfstate_prod" {
  name                  = "tfstate-prod"
  storage_account_name  = data.azurerm_storage_account.storage.name
  container_access_type = "private"
}