provider "azurerm" {
  features {}
  use_oidc = true
}

module "naming" {
  source = "git::https://github.com/Azure/terraform-azurerm-naming.git?ref=75d5afae4cb01f4446025e81f76af6b60c1f927b"
  suffix = ["elkhorn", "dev"]
}

# the resource group for dev environment
resource "azurerm_resource_group" "rg" {
  name     = module.naming.resource_group.name
  location = var.location
  tags = {
    environment = "development"
    managedby   = "terraform"
  }
}

# a storage account for dev environment
module "storage_account" {
  source = "../modules/storage_account"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = module.naming.storage_account.name
  environment         = "development"
}