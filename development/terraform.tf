terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.5"
    }
  }

  backend "azurerm" {
    key              = "development.tfstate"
    use_azuread_auth = true
    use_oidc         = true
  }

  # to switch to local backend from dev env:
  #  1. terraform init -backend-config="storage_account_name=<storage_account_name>" -backend-config="container_name=tfstate" -backend-config="resource_group_name=<resource_group_name>"
  #  2. <switch backends in terraform.tf>
  #  3. terraform init -migrate-state
  #  4. terraform plan should return 'No changes. Your infrastructure matches the configuration.'
  # backend "local" {
  #   path = "development.tfstate"
  # }
}