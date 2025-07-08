
resource "azurerm_service_plan" "asp" {
  name                = "asp-${local.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "F1" # F1 = free, D1 = Development (shared)
  tags                = var.tags

  # check networking (not available on free SKUs)
}

resource "azurerm_linux_web_app" "web_app" {
  for_each = var.web_apps

  name                          = "app-${each.key}-${local.name_suffix}"
  resource_group_name           = var.resource_group_name
  service_plan_id               = azurerm_service_plan.asp.id
  location                      = var.location
  public_network_access_enabled = true # disable when gateway online
  # virtual_network_subnet_id = each.value.subnet_id # not supported on free SKU
  tags = var.tags

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
    always_on = false # must be false for free plans
    # api_management_api_id = azurerm_api_management.apim.id

    application_stack {
      docker_registry_url      = each.value.registry_url
      docker_image_name        = each.value.image_name
      docker_registry_username = each.value.registry_username
      docker_registry_password = each.value.registry_password
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_monitor_diagnostic_setting" "webapp_logs" {
  for_each = var.web_apps

  name                       = "${each.key}-diagnostics"
  target_resource_id         = azurerm_linux_web_app.web_app[each.key].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

/****************************************************************************/
# api management stuff should probably be moved to a separate module.

resource "azurerm_api_management" "apim" {
  name                = "apim-${local.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  publisher_name      = "Stormvale"
  publisher_email     = "kevin@email.com"
  sku_name            = "Consumption_0" # 1M api operations (per month?)
}

# TODO: configure subscriptions for tighter api acess. see "azurerm_api_management_subscription"

resource "azurerm_api_management_api" "apim_api" {
  for_each = var.web_apps

  name                = "${each.key}-api"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  api_type            = "http"
  display_name        = "${each.key} API"
  path                = each.key
  protocols           = ["https"]

  import {
    content_format = "openapi-link"
    content_value  = "https://${azurerm_linux_web_app.web_app[each.key].default_hostname}/openapi/v1.json"
  }
}
