variable "subscription_id" {
  description = "(Required) The Azure subscription ID where the resources should exist."
  type        = string
}

variable "client_id" {
  description = "(Required) The client ID of the GitHub Actions OIDC application."
  type        = string
}

variable "resource_group_name" {
  description = "(Required) The name of the resource group where the resource should exist."
  type        = string
}

####################################################################################

variable "location_map" {
  description = "Maps a long location name to a short code. Used in resource names."
  type        = map(string)
  default = {
    "westus2"       = "wus2",
    "canadacentral" = "cnc"
  }
}