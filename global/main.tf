provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  use_oidc        = true
}

# the service principal for the github application used to run actions
data "azuread_service_principal" "github_actions_sp" {
  client_id = var.client_id
}

# initial resource group, storage account and storage container for state are all created manually
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

###################################################################
# container registry and role assignment for GitHub Actions service principal

resource "azurerm_container_registry" "acr" {
  name                = replace("acr-elkhorn-${lookup(var.location_map, data.azurerm_resource_group.rg.location)}", "-", "") # acrelkhornwus2
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Basic"

  admin_enabled                   = false # CKV_AZURE_137
  # public_network_access_enabled = false # CKV_AZURE_139 (not available on Basic SKU)
  # data_endpoint_enabled         = true  # CKV_AZURE_237 (not available on Basic SKU)
  # quarantine_policy_enabled     = true  # CKV_AZURE_166 (not available on Basic SKU)
  # retention_policy_in_days      = 7     # CKV_AZURE_167 (not available on Basic SKU)

  # georeplications { (not available on Basic SKU)
  #   zone_redundancy_enabled = true
  #   location                = "East US"
  # }
}

resource "azurerm_role_assignment" "github_acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = data.azuread_service_principal.github_actions_sp.object_id
  description          = "Allow GitHub Actions to push to ACR"
}

###################################################################