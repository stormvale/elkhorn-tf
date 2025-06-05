
data "azurerm_client_config" "current" {}

resource "random_id" "rid" {
  byte_length = 4
}

# the resource group for dev environment (use dev workspace)
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.app_name}-dev-${local.location-short}"
  location = var.location
  tags     = local.tags
}

# a keyvault for environment-specific secrets
resource "azurerm_key_vault" "keyvault" {
  name                = "kv-${var.app_name}-dev-${local.location-short}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = local.tags
}

# a storage account for environment-specific stuff
resource "azurerm_storage_account" "storage" {
  name                     = "sto${var.app_name}dev${lower(random_id.rid.id)}" # eg. stoelkhorndevu3G3Pw
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

# a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.app_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.app_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

  sku      = "Basic"
  sku_tier = "Regional"

  tags = local.tags
}