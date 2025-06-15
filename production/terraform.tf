terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }

  backend "azurerm" {
    key              = "production.tfstate"
    use_oidc         = true
    use_azuread_auth = true
  }
}