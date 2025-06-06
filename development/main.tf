
# the resource group for dev environment
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.app_name}-dev-${local.location-short}"
  location = var.location
  tags     = local.tags
}