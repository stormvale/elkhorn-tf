provider "azurerm" {
  subscription_id = var.subscription_id
  use_oidc        = true

  features {
    api_management { purge_soft_delete_on_destroy = true }
    key_vault { purge_soft_delete_on_destroy = true }
    log_analytics_workspace { permanently_delete_on_destroy = true }
  }
}

data "azurerm_client_config" "current" {}

locals {
  tags = {
    env       = local.environment_short
    managedby = "terraform"
  }
}

#############################################################################
# RESOURCES FOR THE DEV ENVIRONMENT
#############################################################################

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name_suffix}" # rg-elkhorn-dev-wus2
  location = var.location
  tags     = local.tags
}

module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_name           = "vnet-${local.name_suffix}" # vnet-elkhorn-dev-wus2
  vnet_address_space  = ["10.0.0.0/16"]             # /16 => first 16 bits (ie. 2 octets) locked => 65k addresses
  environment         = "development"
  tags                = local.tags

  subnets = {
    web_apps = {
      address_prefixes  = ["10.0.1.0/26"] # 10.0.1.0 - 10.0.1.63
      service_endpoints = ["Microsoft.Web", "Microsoft.AzureCosmosDB", "Microsoft.KeyVault"]
      delegation = {
        service_delegation_name = "Microsoft.Web/serverFarms" # this is used for App Service Plans (Web Apps)
        actions                 = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}

module "storage_account" {
  source = "../../modules/storage_account"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = replace("st-${local.name_suffix}", "-", "") # stelkhorndevwus2
  environment         = "development"
  tags                = local.tags
}

module "key_vault" {
  source = "../../modules/key_vault"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  environment         = "development"
  tags                = local.tags
}

resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "log-${local.name_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 1
  tags                = local.tags

  identity { type = "SystemAssigned" }
}

module "cosmosdb" {
  source = "../../modules/cosmosdb"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  environment         = "development"
  allowed_subnet_ids  = [module.networking.subnet_ids["web_apps"]]
  tags                = local.tags

  # To take advantage of the free tier during development, we will use a single database
  # with containers for each service, instead of the preferred "database per service" approach.
  cosmos_databases = {
    elkhornDb = {
      throughput = 1000 # Free tier max = 1000 RU/s per account
      containers = {
        restaurants = { partition_key_paths = ["/id"] }
        schools     = { partition_key_paths = ["/id"] }
        lunches     = { partition_key_paths = ["/id"] }
        orders      = { partition_key_paths = ["/id"] }
      }
    }
  }
}

module "web_apps" {
  source = "../../modules/web_apps"

  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  environment                = "development"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id
  environment_keyvault_id    = module.key_vault.key_vault_id
  tags                       = local.tags

  # the key names are important, as they are used to generate the db connection string name where required.
  web_apps = {
    restaurants = {
      registry_url               = "https://ghcr.io"
      registry_username          = var.registry_username
      registry_password          = var.registry_password
      image_name                 = "stormvale/restaurants.api:latest",
      cosmosdb_connection_string = module.cosmosdb.account_connection_string
      subnet_id                  = module.networking.subnet_ids["web_apps"]
    }
    schools = {
      registry_url               = "https://ghcr.io"
      registry_username          = var.registry_username
      registry_password          = var.registry_password
      image_name                 = "stormvale/schools.api:latest",
      cosmosdb_connection_string = module.cosmosdb.account_connection_string
      subnet_id                  = module.networking.subnet_ids["web_apps"]
    }
  }
}

###########################################################################

