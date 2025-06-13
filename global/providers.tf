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
    key              = "global.tfstate"
    use_azuread_auth = true
    use_oidc         = true
  }

  # to switch to local backend from dev env:
  #  1. terraform init -backend-config="resource_group_name=<resource_group_name>" -backend-config="storage_account_name=<storage_account_name>" -backend-config="container_name=tfstate"
  #  2. <switch backends in terraform.tf>
  #  3. terraform init -migrate-state
  #  4. terraform plan should return 'No changes. Your infrastructure matches the configuration.'
  # backend "local" {
  #   path = "global.tfstate"
  # }
}