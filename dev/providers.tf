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
    storage_account_name = "tfstate71d6f"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    # use_oidc             = true
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_secrets_on_destroy = true
      recover_soft_deleted_secrets          = true
    }
  }
  use_oidc = true # this could be set through an environment variable as well?
}