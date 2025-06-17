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
    gateway = {
      address_prefixes  = ["10.0.0.0/24"] # 10.0.0.0 - 10.0.0.255
      service_endpoints = []
    }
  }

  tags = {
    environment = "development"
    managedby   = "terraform"
  }
}

# also, look into "azurerm_virtual_network_gateway"

module "storage_account" {
  source = "../modules/storage_account"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = replace("st-${local.name_suffix}", "-", "") # stelkhorndevwus2
  environment         = "development"

  subnet_ids = [
    azurerm_subnet.cae_subnet.id
  ]

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

  tags = {
    environment = "development"
    managedby   = "terraform"
  }
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

resource "azurerm_container_app_environment" "cae" {
  name                       = "cae-${local.name_suffix}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id
  zone_redundancy_enabled    = false

  # workload profiles:
  #  - require min /27 subnet for vnet integration
  #  - subnet must be delegated to Microsoft.App/environments
  infrastructure_subnet_id = azurerm_subnet.cae_subnet.id

  # Azure automatically creates this separate resource group to hold the infrastructure components.
  # It is managed by the Azure Container Apps platform. Container Apps are still deployed into the
  # main resource group containing the Container Apps Environment.
  infrastructure_resource_group_name = "${azurerm_resource_group.rg.name}-cae"

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
    minimum_count         = 0
    maximum_count         = 2
  }

  tags = {
    environment = "development"
    managedby   = "terraform"
  }
}

resource "azurerm_subnet" "cae_subnet" {
  name                 = "snet-cae-${local.name_suffix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = module.networking.virtual_network_name
  address_prefixes     = ["10.0.2.0/23"] # 10.0.2.0 - 10.0.3.255 (cae subnet requires at least /23)
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_container_app" "api_weather" {
  name                         = "api-weather"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "api-weather" # lower case alphanumeric characters or '-'. max 63 chars
      image  = "ghcr.io/stormvale/api.weather:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env { # environment variables here
        name  = "DEFAULT_CITY"
        value = "Vancouver"
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  registry {
    server               = "ghcr.io"
    username             = var.registry_username
    password_secret_name = "gh-pat-secret"
  }

  tags = {
    environment = "development"
    managedby   = "terraform"
  }
}

# this container app is allowed to contribute to log analytics
resource "azurerm_role_assignment" "role_weather_api_log" {
  scope                = azurerm_log_analytics_workspace.log_workspace.id
  principal_id         = azurerm_container_app.api_weather.identity[0].principal_id
  role_definition_name = "Log Analytics Contributor"
}

# this container app is allowed to access keyvault secrets
resource "azurerm_role_assignment" "role_weather_api_kv" {
  scope                = azurerm_container_app.api_weather.id
  principal_id         = azurerm_container_app.api_weather.identity[0].principal_id
  role_definition_name = "Key Vault Secrets User"
}