
resource "azurerm_virtual_network" "network" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = [each.value]
}

resource "azurerm_network_security_group" "nsgs" {
  for_each            = var.subnets
  name                = "nsg-${each.key}-${local.name_suffix}" # nsg-<subnet_name>-elkhorn-dev-wus2
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "rules" {
  for_each                    = var.subnets
  name                        = "allow-https"
  description                 = "Allow HTTPS traffic to ${each.key} subnet"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsgs[each.key].name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each                  = var.subnets
  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsgs[each.key].id
}
