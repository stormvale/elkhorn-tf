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

  # backend "local" {
  #   path = "development.tfstate"
  # }
}