provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  use_oidc        = true
}

#############################################################################
# RESOURCES FOR THE DEV ENVIRONMENT
#############################################################################

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name_suffix}" # rg-elkhorn-dev-wus2
  location = var.location
  tags = {
    environment = "development"
    managedby   = "terraform"
  }
}

module "networking" {
  source = "../modules/networking"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_name           = "vnet-${local.name_suffix}" # vnet-elkhorn-dev-wus2
  vnet_address_space  = ["10.0.0.0/16"]             # /16 => first 16 bits (ie. 2 octets) locked => 65k addresses
  environment         = "development"

  subnets = {
    gateway = "10.0.0.0/24" # /24 => 255 addresses
    cae     = "10.0.1.0/24"
  }

  tags = {
    environment = "development"
    managedby   = "terraform"
  }
}

module "storage_account" {
  source = "../modules/storage_account"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = replace("st-${local.name_suffix}", "-", "") # stelkhorndevwus2
  environment         = "development"
  subnet_ids          = [ module.networking.subnets["cae"] ]

  tags = {
    environment = "development"
    managedby   = "terraform"
  }
}

resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "log-${local.name_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 1
}

###########################################################################
# resources for weather-api app

data "azurerm_key_vault" "kv_shared" {
  name                = "kv-elkhorn-${local.location_short}"
  resource_group_name = "rg-elkhorn-${local.location_short}"
}

data "azurerm_key_vault_secret" "github_pat" {
  name         = "github-pat"
  key_vault_id = data.azurerm_key_vault.kv_shared.id
}

resource "azurerm_container_app_environment" "env" {
  name                       = "cae-${local.name_suffix}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id
  infrastructure_subnet_id   = module.networking.subnets["cae"]
  zone_redundancy_enabled    = false

  tags = {
    environment = "development"
    managedby   = "terraform"
  }
}

resource "azurerm_container_app" "api_weather" {
  name                         = "api-weather"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "api-weather"
      image  = "ghcr.io/stormvale/weather-api:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
    min_replicas = 0
    max_replicas = 2

    # scale rules
  }

  registry {
    server               = "ghcr.io"
    username             = var.registry_username
    password_secret_name = data.azurerm_key_vault_secret.github_pat.name
  }
}

# a managed identity for this container app
resource "azurerm_user_assigned_identity" "api_weather_id" {
  name                = "id-${azurerm_container_app.api_weather.name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# this container app is allowed to contribute to log analytics
resource "azurerm_role_assignment" "role" {
  scope                = azurerm_log_analytics_workspace.log_workspace.id
  principal_id         = azurerm_user_assigned_identity.api_weather_id.principal_id
  role_definition_name = "Log Analytics Contributor"
}