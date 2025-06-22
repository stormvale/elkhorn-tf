provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  use_oidc        = true
}

data "azurerm_client_config" "current" {}

locals {
  tags = {
    environment = "development"
    managedby   = "terraform"
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
    gateway = {
      address_prefixes  = ["10.0.0.0/24"] # 10.0.0.0 - 10.0.0.255
      service_endpoints = []
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

  # subnet_ids = [
  #   azurerm_subnet.cae_subnet.id
  # ]
}

resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "log-${local.name_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 1
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }
}

module "container_app_env" {
  source = "../../modules/container_app_env"

  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id
  virtual_network_name       = module.networking.virtual_network_name
  subnet_cidr                = "10.0.2.0/23"
  environment                = "development"
  tags                       = local.tags
}

###########################################################################
# resources for api services

data "azurerm_key_vault" "kv_shared" {
  name                = "kv-elkhorn-${local.location_short}"
  resource_group_name = "rg-elkhorn-${local.location_short}"
}

data "azurerm_key_vault_secret" "github_pat" {
  name         = "github-pat"
  key_vault_id = data.azurerm_key_vault.kv_shared.id
}

resource "azurerm_container_app" "api_weather" {
  name                         = "api-weather-${local.name_suffix}"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = module.container_app_env.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  tags                         = local.tags

  template {
    container {
      name   = "api-weather"
      image  = "ghcr.io/stormvale/api.weather:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env { # environment variables can refer to secrets
        name        = "ConnectionStrings__postgres"
        secret_name = "conn-string-postgres"
      }
    }

    # init_container { <ef migrations> }

    min_replicas = 0
    max_replicas = 2
  }

  ingress {
    external_enabled = false
    target_port      = 80

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  identity {
    type         = "SystemAssigned, UserAssigned" # would like to switch to "SystemAssigned"
    identity_ids = [azurerm_user_assigned_identity.api_weather_id.id]
  }

  secret {
    name                = "gh-pat-secret"
    identity            = azurerm_user_assigned_identity.api_weather_id.id # "System"
    key_vault_secret_id = data.azurerm_key_vault_secret.github_pat.id
  }

  secret {
    name  = "conn-string-postgres"
    value = "<db connection string goes here>"
  }

  registry {
    server               = "ghcr.io"
    username             = var.registry_username
    password_secret_name = "gh-pat-secret"
  }

  lifecycle {
    ignore_changes = [secret] # recommended when using key_vault_secret_id
  }
}

################

# a user assigned managed identity for this container app.
resource "azurerm_user_assigned_identity" "api_weather_id" {
  name                = "id-api-weather-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

# this user assigned managed identity can read key vault secrets
resource "azurerm_role_assignment" "role_weather_api_kv" {
  scope                = data.azurerm_key_vault.kv_shared.id
  principal_id         = azurerm_user_assigned_identity.api_weather_id.principal_id
  role_definition_name = "Key Vault Secrets User"
}

################

# Since the container app’s identity doesn’t exist until the resource is created, you may hit a chicken-and-egg problem
# when referencing Key Vault secrets during the same deployment. To avoid this:
# - Option 1: Deploy the container app without secrets first, then assign the role, then redeploy with secrets.
# - Option 2: Use a null_resource or external script to orchestrate the two-step deployment.
# - Option 3: Use a user-assigned identity instead, which can be created and granted access ahead of time.
# resource "azurerm_role_assignment" "keyvault_access" {
#   scope                = data.azurerm_key_vault.kv_shared.id # shared key vault
#   principal_id         = azurerm_container_app.api_weather.identity[0].principal_id # using system assigned managed identity
#   role_definition_name = "Key Vault Secrets User"
# }

################

# this container app is allowed to read secret values from the shared key vault.
# UPDATE: using an access policy for the system assigned managed identity doesn't seem to work either
# resource "azurerm_key_vault_access_policy" "container_app_policy" {
#   key_vault_id       = data.azurerm_key_vault.kv_shared.id
#   tenant_id          = data.azurerm_client_config.current.tenant_id
#   object_id          = azurerm_container_app.api_weather.identity[0].principal_id # system assigned managed identity
#   secret_permissions = ["Get", "List"]
# }

# this container app is allowed to contribute to log analytics.
# UPDATE: i don't think we need this, since we are setting the log analytics workspace id on the container apps environment
# resource "azurerm_role_assignment" "role_weather_api_log" {
#   scope                = azurerm_log_analytics_workspace.log_workspace.id
#   principal_id         = azurerm_container_app.api_weather.identity[0].principal_id # system assigned managed identity
#   role_definition_name = "Log Analytics Contributor"
#   depends_on = [ azurerm_log_analytics_workspace.log_workspace ]
# }
