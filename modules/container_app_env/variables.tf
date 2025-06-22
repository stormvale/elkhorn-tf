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

variable "virtual_network_name" {
  description = "(Required) The name of the virtual network to which to attach the new subnet for the Container Apps Environment."
  type        = string
}

variable "subnet_cidr" {
  description = "(Required) The address range in CIDR notation for the new subnet. Container Apps Environment requires at least /23"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "(Optional) The ID for the Log Analytics Workspace to link this Container Apps Managed Environment to."
  type        = string
  default     = null
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