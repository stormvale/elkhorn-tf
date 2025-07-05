
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
  tags                          = var.tags

  # not supported on free SKU
  # virtual_network_subnet_id = each.value.subnet_id

  # not all services have a connection string
  dynamic "connection_string" {
    for_each = each.value.cosmosdb_connection_string != null ? [each.value.cosmosdb_connection_string] : []
    content {
      name = "${each.key}Db"
      type  = "Custom"
      value = each.value.cosmosdb_connection_string
    }
  }

  site_config {
    always_on = false # must be off for free plans

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

  # logs {
  #   application_logs {
  #     file_system_level = "Warning"

  #     azure_blob_storage {
  #       level = "Warning"
  #       retention_in_days = 7
  #       sas_url = "<SAS url to an Azure blob container with read/write/list/delete permissions>"
  #     }
  #   }
  # }
}


# still working on this:
# resource "azurerm_monitor_diagnostic_setting" "webapp_diagnostics" {
#   for_each            = var.web_apps

#   name                       = "${each.key}-diagnostics"
#   target_resource_id         = azurerm_linux_web_app.web_app.id # not sure if this ref is good?
#   log_analytics_workspace_id = var.analytics_workspace_id

#   enabled_log {
#     category = "AuditEvent"
#   }
# }
