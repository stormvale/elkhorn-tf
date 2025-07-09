variable "resource_group_name" {
  description = "(Required) The name of the resource group where the resource should exist."
  type        = string
}

variable "location" {
  description = "(Required) The Azure region where the resource should exist"
  type        = string

  validation {
    condition     = contains(["westus2", "canadacentral"], var.location)
    error_message = "Allowed values for location are \"westus2\", \"canadacentral\"."
  }
}

variable "environment" {
  description = "(Required) The environment of the resource. Valid options are 'development' and 'production'."
  type        = string

  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "Allowed values for environment are \"development\", \"production\"."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "web_apps" {
  description = "Map of Web Apps to deploy"
  type = map(object({
    registry_url               = string
    registry_username          = string
    registry_password          = string
    image_name                 = string
    cosmosdb_connection_string = optional(string)
    subnet_id                  = string # not used (free tier)
  }))
}

variable "log_analytics_workspace_id" {
  description = "(Required) The id of the Log Analytics Workspace where App logs should be sent."
  type        = string
}

variable "environment_keyvault_id" {
  description = "(Required) Resource ID of the Key Vault used by web apps to read secrets."
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

variable "environment_map" {
  description = "Maps a long environment name to a short code. Used in resource names."
  type        = map(string)
  default = {
    "development" = "dev",
    "production"  = "prod"
  }
}

locals {
  location_short    = lookup(var.location_map, var.location)
  environment_short = lookup(var.environment_map, var.environment)
  name_suffix       = "elkhorn-${local.environment_short}-${local.location_short}"
}