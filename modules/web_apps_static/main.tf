
resource "azurerm_static_web_app" "web_app" {
  name                = "stapp-${local.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_tier            = "Free"
  sku_size            = "Free"
  tags                = var.tags

  # identity { # requires a standard hosting plan
  #   type = "SystemAssigned, UserAssigned"
  #   identity_ids = [azurerm_user_assigned_identity.web_app_id.id]
  # }
}