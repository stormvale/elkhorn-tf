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

variable "vnet_name" {
  description = "(Required) The name of the resource."
  type        = string
}

variable "vnet_address_space" {
  type        = list(string)
  description = "(Optional) Address space for virtual network, defaults to 10.0.0.0/16."
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = list(string)
  }))
  description = "(Optional) Subnets to create in the virtual network. The key is the subnet name"
}

variable "tags" {
  description = "A map of tags to assign to the resource. Tags for 'environment' and 'managedby' are automatically assigned."
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
  location_short    = lookup(var.location_map, var.location)
  environment_short = lookup(var.environment_map, var.environment)
  name_suffix       = "elkhorn-${local.environment_short}-${local.location_short}"
}