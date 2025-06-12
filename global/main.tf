provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  use_oidc        = true
}

# the service principal for the github application used to run actions
data "azuread_service_principal" "github_actions_oidc_sp" {
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
  admin_enabled       = false
}

resource "azurerm_role_assignment" "github_acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = data.azuread_service_principal.github_actions_oidc_sp.object_id
  description          = "Allow GitHub Actions OIDC to push to ACR"
}

###################################################################