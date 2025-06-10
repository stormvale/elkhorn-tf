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

resource "azurerm_virtual_network" "net1" {
  name                = module.naming.virtual_network.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  depends_on          = [azurerm_resource_group.rg]
}

# a storage account for dev environment
module "storage_account" {
  source = "../modules/storage_account"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = module.naming.storage_account.name
  environment         = "development"
}

module "networking" {
  source = "../modules/networking"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_name           = module.naming.virtual_network.name
  vnet_address_space  = ["10.0.0.0/16"]
  environment         = "development"

  subnets = {
    gateway = "10.0.1.0/24"
    subnet2 = "10.0.2.0/24"
  }
}