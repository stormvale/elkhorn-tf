
variable "resource_group_name" {
  description = "(Required) The name of the Resource Group where the Container App should exist."
  type        = string
}

variable "container_app_environment_id" {
  description = "(Required) The ID of the Conatiner App Environment where the Container App should exist."
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

variable "registry_username" {
  description = "(Required) The username to use to access the configured container registry."
  type        = string
}

variable "environment_keyvault_id" {
  description = "(Required) Resource ID of the Key Vault used by container apps to read secrets."
  type        = string
}

variable "container_apps_identity_id" {
  description = "(Required) Resource ID for a user-assigned managed identity with the 'Key Vault Secrets User' role."
  type        = string
}

variable "servicebus_namespace_id" {
  description = "(Required) Resource ID for the servicebus namespace used by the Dapr pubsub component."
  type        = string
}


variable "container_apps" {
  description = "(Required) Azure Container App resources that should exist."

  type = map(object({
    image           = string
    cpu             = number
    memory          = string
    ingress_enabled = bool

    # environment variables either have a vlue, or reference a named secret from the 'secrets' block
    environment_variables = list(object({
      name        = string
      value       = optional(string)
      secret_name = optional(string)
    }))

    # secrets either have a value, or a key vault secret id
    secrets = optional(list(object({
      name                = string
      value               = optional(string) # value is ignored if key_vault_secret_id is provided
      key_vault_secret_id = optional(string)
    })), [])
  }))

  # validation {
  #   condition = alltrue([
  #     for env in var.container_apps.environment_variables :
  #     (
  #       (env.value != null && env.secret_name == null) ||
  #       (env.value == null && env.secret_name != null)
  #     )
  #   ])
  #   error_message = "Each environment variable must have either 'value' or 'secret_name', but not both."
  # }

  # validation {
  #   condition = alltrue(flatten([
  #     for app in values(var.container_apps) : [
  #       for s in app.secrets : (
  #         (s.value != null && s.key_vault_secret_id == null && s.identity == null) ||
  #         (s.value == null && s.key_vault_secret_id != null && s.identity != null)
  #       )
  #     ]
  #   ]))
  #   error_message = "Each secret must have either a 'value' or both 'key_vault_secret_id' and 'identity', but not both."
  # }
}

variable "dapr_components" {
  description = "List of Dapr components to provision."
  type = set(object({
    name           = string
    component_type = string
    scopes         = optional(set(string), [])
    metadata = optional(list(object({
      name        = string
      value       = optional(string)
      secret_name = optional(string)
    })), [])
    secret = optional(list(object({
      name  = string
      value = string
    })), [])
  }))
  default = []
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