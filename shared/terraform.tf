terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.32.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "3.4.0"
    }
  }

  backend "azurerm" {
    key              = "shared.tfstate"
    use_azuread_auth = true
    use_oidc         = true
  }
  # backend "local" {
  #   path = "global.tfstate"
  # }

  # To switch to local backend from remote state
  # ============================================
  # 1. Ensure you're logged in to Azure CLI with the Github Actions service principal
  #       az login --service-principal --username APP_ID --password CLIENT_SECRET --tenant TENANT_ID
  # 2. Initialize the backend locally using the remote state
  #       terraform init -backend-config="resource_group_name=<RESOURCE_GROUP_NAME>" -backend-config="storage_account_name=<STORAGE_ACCOUNT_NAME>" -backend-config="container_name=tfstate"
  # 3. Update terraform.tf to use the "local" backend instead of "azurerm"
  # 4. The backend has changed, so we need to re-initialize, but keep the state
  #       terraform init -migrate-state
  # 5. terraform plan should return 'No changes. Your infrastructure matches the configuration.'


  # To import an existing resource into state
  # =========================================
  #       terraform import <fully qualified name of the resource> /subscriptions/<subscription_id>/resourceGroups/<resource_group_name>/providers/Microsoft.App/...<etc.>
}