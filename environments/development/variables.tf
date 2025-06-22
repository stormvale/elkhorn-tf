
variable "subscription_id" {
  description = "(Required) The Azure subscription ID where the resources should exist."
  type        = string
}

variable "registry_username" {
  description = "(Required) GitHub username to access the GitHub Container Registry."
  type        = string
}

variable "location" {
  description = "(Required) The Azure region where the resource should exist."
  type        = string

  validation {
    condition     = contains(["westus2", "canadacentral"], var.location)
    error_message = "Allowed values for location are 'westus2', 'canadacentral'."
  }
}

# variable "container_apps" {
#   description = "Azure Container App resources that should exist"
#   type = map(object({
#     image  = string
#     cpu    = number
#     memory = string

#     env_vars = list(object({
#       name        = string
#       value       = optional(string)
#       secret_name = optional(string)
#     }))

#     secrets = optional(list(object({
#       name  = string
#       value = string
#     })), [])

#   }))
# }

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
  environment_short = lookup(var.environment_map, "development")
  name_suffix       = "elkhorn-${local.environment_short}-${local.location_short}"
}