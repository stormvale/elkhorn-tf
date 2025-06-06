terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-elkhorn-wus2"
    storage_account_name = "stoelkhornu3g3pw"
    container_name       = "tfstate-prod"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
  }
}