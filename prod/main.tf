
# the resource group for prod environment
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.app_name}-prod-${local.location-short}"
  location = var.location
  tags     = local.tags
}