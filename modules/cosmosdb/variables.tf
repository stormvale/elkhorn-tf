
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
  description = "(Optional) The environment of the resource. Valid options are 'development' and 'production'. Shared resources may have no environment."
  type        = string
  nullable    = true

  validation {
    condition     = var.environment == null || contains(["development", "production"], var.environment)
    error_message = "Allowed values for environment are \"development\", \"production\"."
  }
}

variable "cosmos_databases" {
  description = "Map of Cosmos DB databases and their container configurations. Note: for development, all containers will be created in a single database named 'elkhornDb'"
  type = map(object({
    throughput = optional(number)
    containers = map(object({
      partition_key_paths = set(string)
      throughput          = optional(number)
    }))
  }))
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
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
  environment_short = var.environment != null ? "-${lookup(var.environment_map, var.environment)}" : ""
  location_short    = lookup(var.location_map, var.location)
  name_suffix       = "elkhorn${local.environment_short}-${local.location_short}"
}