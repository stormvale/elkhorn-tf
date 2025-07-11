
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

# TODO: other things to configure:
#   - subscriptions for tighter api acess (see "azurerm_api_management_subscription")
#   - product (see "azurerm_api_management_product")
#   - custom gateway? (there is a built-in one already)
#   - identity providers?

resource "azurerm_api_management_api" "apis" {
  for_each            = { for api in var.apis : api.name => api } # Only executed if var.apis is non-empty
  name                = each.value.name
  display_name        = each.value.display_name
  path                = each.value.path
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.resource_group_name
  api_type            = "http"
  revision            = "1"
  protocols           = lookup(each.value, "protocols", ["https"])
  service_url         = each.value.service_url

  import {
    content_format = "openapi-link"
    content_value  = "${each.value.service_url}/openapi/v1.json"
  }
}