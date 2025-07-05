
resource "azurerm_container_app_environment" "cae" {
  name                       = "cae-${local.name_suffix}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  zone_redundancy_enabled    = false
  tags                       = var.tags

  # workload profiles:
  #  - require min /27 subnet for vnet integration
  #  - subnet must be delegated to Microsoft.App/environments
  infrastructure_subnet_id = azurerm_subnet.cae_subnet.id

  # Azure automatically creates this separate resource group to hold the infrastructure components.
  # It is managed by the Azure Container Apps platform. Container Apps are still deployed into the
  # main resource group containing the Container Apps Environment.
  infrastructure_resource_group_name = "${var.resource_group_name}-cae"

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
    minimum_count         = 0
    maximum_count         = 2
  }

  lifecycle {
    ignore_changes = [workload_profile] # this seems to always be changing...?
  }
}

# a subnet for the container app environment
resource "azurerm_subnet" "cae_subnet" {
  name                 = "snet-cae-${local.name_suffix}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_cidr] # cae subnet requires at least /23
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}