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

  secrets = {
    container-registry-username = var.registry_username
    container-registry-password = var.registry_password
    cosmosdb-connection-string  = module.cosmosdb.account_connection_string
  }
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

module "service_bus" {
  source = "../../modules/servicebus"

  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  environment         = "development"
  tags                = local.tags

  topics = [] # a topic for each microservice is created in the container_apps module
}

# a shared user-assigned managed identity for container apps
resource "azurerm_user_assigned_identity" "container_apps_identity" {
  name                = "id-ca-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

# container apps can read key vault secrets
resource "azurerm_role_assignment" "role_ca_kv_secrets_user" {
  scope                = module.key_vault.key_vault_id
  principal_id         = azurerm_user_assigned_identity.container_apps_identity.principal_id
  role_definition_name = "Key Vault Secrets User"
}

# container apps can create service bus topics (dapr needs this)
resource "azurerm_role_assignment" "role_ca_sbns_data_owner" {
  scope                = module.service_bus.id
  principal_id         = azurerm_user_assigned_identity.container_apps_identity.principal_id
  role_definition_name = "Azure Service Bus Data Owner"
}

module "cosmosdb" {
  source = "../../modules/cosmosdb"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  environment         = "development"
  # allowed_subnet_ids  = [module.networking.subnet_ids["web_apps"]]
  tags = local.tags

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

module "container_app_env" {
  source = "../../modules/container_app_env"

  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id
  environment                = "development"
  tags                       = local.tags

  # disabling networking stuff to try to keep azure from creating the load balancer => $$
  # virtual_network_name       = module.networking.virtual_network_name
  # subnet_cidr                = "10.0.2.0/23"
}

module "container_apps" {
  source = "../../modules/container_apps"

  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  environment_keyvault_id      = module.key_vault.key_vault_id
  container_app_environment_id = module.container_app_env.id
  container_apps_identity_id   = azurerm_user_assigned_identity.container_apps_identity.id
  registry_username            = var.registry_username
  environment                  = "development"
  servicebus_namespace_id      = module.service_bus.id
  tags                         = local.tags

  container_apps = {
    restaurants = {
      cpu             = 0.25
      memory          = "0.5Gi"
      image           = "ghcr.io/stormvale/restaurants.api:latest"
      ingress_enabled = true

      secrets = [
        {
          name                = "db-conn-string"
          key_vault_secret_id = module.key_vault.secret_ids["cosmosdb-connection-string"]
        },
        {
          name                = "gh-pat-secret"
          key_vault_secret_id = module.key_vault.secret_ids["container-registry-password"]
        }
      ]

      environment_variables = [
        {
          name        = "ConnectionStrings__cosmos-db"
          secret_name = "db-conn-string"
        },
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "Development"
        }
      ]
    }
    schools = {
      cpu             = 0.25
      memory          = "0.5Gi"
      image           = "ghcr.io/stormvale/schools.api:latest"
      ingress_enabled = true

      secrets = [
        {
          name                = "db-conn-string"
          key_vault_secret_id = module.key_vault.secret_ids["cosmosdb-connection-string"]
        },
        {
          name                = "gh-pat-secret"
          key_vault_secret_id = module.key_vault.secret_ids["container-registry-password"]
        }
      ]

      environment_variables = [
        {
          name        = "ConnectionStrings__cosmos-db"
          secret_name = "db-conn-string"
        },
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "Development"
        }
      ]
    }
    users = {
      cpu             = 0.25
      memory          = "0.5Gi"
      image           = "ghcr.io/stormvale/users.api:latest"
      ingress_enabled = true

      secrets = [
        {
          name                = "db-conn-string"
          key_vault_secret_id = module.key_vault.secret_ids["cosmosdb-connection-string"]
        },
        {
          name                = "gh-pat-secret"
          key_vault_secret_id = module.key_vault.secret_ids["container-registry-password"]
        }
      ]

      environment_variables = [
        {
          name        = "ConnectionStrings__cosmos-db"
          secret_name = "db-conn-string"
        },
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "Development"
        }
      ]
    }
  }

  dapr_components = [
    {
      name           = "secretstore"
      component_type = "secretstores.azure.keyvault"
      scopes         = ["restaurants-api", "schools-api"]
      metadata = [
        { name = "vaultName", value = module.key_vault.key_vault_name },
        { name = "spnClientId", value = azurerm_user_assigned_identity.container_apps_identity.client_id }
      ]
    },
    {
      name           = "pubsub"
      component_type = "pubsub.azure.servicebus.topics"
      scopes         = ["restaurants-api", "schools-api"]
      metadata = [
        { name = "connectionString", secret_name = "servicebus-conn" },
        { name = "createTopicIfNotExists", value = "true" }
      ]
      secret = [
        { name = "servicebus-conn", value = module.service_bus.dapr_access_connection_string }
      ]
    }
  ]
}

module "api_management" {
  source = "../../modules/api_management"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  environment         = "development"
  tags                = local.tags

  apis = [
    {
      name         = "restaurants-api"
      display_name = "Restaurants API"
      path         = "restaurants"
      revision     = "1"
      protocols    = ["https"]
      service_url  = module.container_apps.container_app_urls["restaurants"]
    },
    {
      name         = "schools-api"
      display_name = "Schools API"
      path         = "schools"
      revision     = "1"
      protocols    = ["https"]
      service_url  = module.container_apps.container_app_urls["schools"]
    }
  ]
}

module "web_app" {
  source = "../../modules/web_apps_static"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  environment         = "development"
  tags                = local.tags
}