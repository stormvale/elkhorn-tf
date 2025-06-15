variable "subscription_id" {
  description = "(Required) The Azure subscription ID where the resources should exist."
  type        = string
}

variable "client_id" {
  description = "(Required) The client ID of the GitHub Actions application."
  type        = string
}

variable "resource_group_name" {
  description = "(Required) The name of the resource group where the resource should exist."
  type        = string
}

variable "github_pat" {
  description = "(Required) The PAT used to authenticate against the GitHub Container Registry."
  type        = string
  sensitive   = true
}

variable "location" {
  description = "(Optional) Azure region where the resources should exist"
  type        = string
  default     = "westus2"
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

locals {
  location_short = lookup(var.location_map, var.location)
  name_suffix    = "elkhorn-${local.location_short}"
}