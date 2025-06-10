
resource "azurerm_virtual_network" "network" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location

  address_space = var.vnet_address_space

  tags = var.tags
}

resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = [each.value]
}