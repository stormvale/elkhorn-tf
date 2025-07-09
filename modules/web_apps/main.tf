
resource "azurerm_service_plan" "asp" {
  name                = "asp-${local.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1" # B1 = lowest tier with vnets (+ health) ~0.017 USD per hour per instance. (F1 = free)
  tags                = var.tags
}

resource "azurerm_linux_web_app" "web_app" {
  for_each = var.web_apps

  name                          = "app-${each.key}-${local.name_suffix}"
  resource_group_name           = var.resource_group_name
  service_plan_id               = azurerm_service_plan.asp.id
  location                      = var.location
  public_network_access_enabled = true # i think this needs to be enabled until we can start using private ip's
  virtual_network_subnet_id     = each.value.subnet_id
  tags                          = var.tags

  # not all services have a connection string
  dynamic "connection_string" {
    for_each = each.value.cosmosdb_connection_string != null ? [each.value.cosmosdb_connection_string] : []
    content {
      name  = "elkhornDb" # "${each.key}Db"
      type  = "Custom"
      value = each.value.cosmosdb_connection_string
    }
  }

  site_config {
    always_on                         = false # must be false for free plans
    health_check_path                 = "/health"
    health_check_eviction_time_in_min = "10"
    api_definition_url                = "https://app-${each.key}-${local.name_suffix}.azurewebsites.net/openapi/v1.json"
    api_management_api_id             = azurerm_api_management_api.apim_api[each.key].id

    application_stack {
      docker_registry_url      = each.value.registry_url
      docker_image_name        = each.value.image_name
      docker_registry_username = each.value.registry_username
      docker_registry_password = each.value.registry_password
    }
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT" = "Development"
  }

  identity { type = "SystemAssigned" }
}

resource "azurerm_monitor_diagnostic_setting" "webapp_logs" {
  for_each = var.web_apps

  name                       = "${each.key}-diagnostics"
  target_resource_id         = azurerm_linux_web_app.web_app[each.key].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AppServiceAppLogs" }
  enabled_log { category = "AppServiceConsoleLogs" }
  enabled_metric { category = "AllMetrics" }
}

# each web app needs to be able to read secrets from the key vault
resource "azurerm_role_assignment" "webapp_kv_access" {
  for_each = azurerm_linux_web_app.web_app

  scope                = var.environment_keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.identity[0].principal_id
}

/**********************************************************/
# should api management stuff be moved to a separate module?

resource "azurerm_api_management" "apim" {
  name                = "apim-${local.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  publisher_name      = "Stormvale"
  publisher_email     = "kevin@email.com"
  sku_name            = "Consumption_0" # 1M api operations (per month?)
  tags                = var.tags

  identity { type = "SystemAssigned" }
}

# TODO: configure subscriptions for tighter api acess. see "azurerm_api_management_subscription"

resource "azurerm_api_management_api" "apim_api" {
  for_each = var.web_apps

  name                 = "${each.key}-api"
  resource_group_name  = var.resource_group_name
  api_management_name  = azurerm_api_management.apim.name
  revision             = "1"
  api_type             = "http"
  display_name         = "${each.key} API"
  terms_of_service_url = "https://opensource.org/licenses/MIT"
  path                 = each.key
  protocols            = ["https"]

  import {
    content_format = "openapi-link"
    content_value  = "https://app-${each.key}-${local.name_suffix}.azurewebsites.net/openapi/v1.json"
  }
}
