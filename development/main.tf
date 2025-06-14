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

resource "azurerm_service_plan" "asp" {
  name                = "asp-${local.name_suffix}" # asp-elkhorn-dev-wus2
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"

  tags = {
    environment = "development"
    managedby   = "terraform"
  }
}

locals {
  api_weather_app_name = "api-weather"
}

resource "azurerm_linux_web_app" "api_weather" {
  name                = "${local.api_weather_app_name}-${local.name_suffix}" # api-weather-elkhorn-dev-wus2
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    always_on           = false # must be false for free tier
    minimum_tls_version = "1.2"

    application_stack {
      docker_registry_url      = "https://ghcr.io"
      docker_image_name        = "ghcr.io/stormvale/weather-api:latest"
      docker_registry_username = var.docker_registry_username
      docker_registry_password = var.docker_registry_password
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  tags = {
    environment = "development"
    managedby   = "terraform"
  }
}