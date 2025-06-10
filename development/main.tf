provider "azurerm" {
  features {}
  use_oidc = true
}

# the resource group for dev environment
resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name_suffix}" # rg-elkhorn-dev-wus2
  location = var.location
  tags = {
    environment = "development"
    managedby   = "terraform"
  }
}

# the networking module for dev environment
module "networking" {
  source = "../modules/networking"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_name           = "vnet-${local.name_suffix}" # vnet-elkhorn-dev-wus2
  vnet_address_space  = ["10.0.0.0/16"]
  environment         = "development"

  subnets = {
    gateway = "10.0.1.0/24"
    subnet2 = "10.0.2.0/24"
  }

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
  name                = replace("st-${local.name_suffix}", "-", "") # stelkhorndevwus2
  environment         = "development"

  tags = {
    environment = "development"
    managedby   = "terraform"
  }
}