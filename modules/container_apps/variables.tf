
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

variable "container_apps" {
  description = "(Optional) Azure Container App resources that should exist."

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

    # secrets either have a value, or a key vault secret id and a managed identity used to access it.
    secrets = optional(list(object({
      name                = string
      value               = optional(string)
      identity            = optional(string)
      key_vault_secret_id = optional(string)
    })), [])
  }))

  default = []

  validation {
    condition = alltrue([
      for env in var.container_apps.env_vars :
      (
        (env.value != null && env.secret_name == null) ||
        (env.value == null && env.secret_name != null)
      )
    ])
    error_message = "Each environment variable must have either 'value' or 'secret_name', but not both."
  }

  validation {
    condition = alltrue(flatten([
      for app in values(var.container_apps) : [
        for s in app.secrets : (
          (s.value != null && s.key_vault_secret_id == null && s.identity == null) ||
          (s.value == null && s.key_vault_secret_id != null && s.identity != null)
        )
      ]
    ]))
    error_message = "Each secret must have either a 'value' or both 'key_vault_secret_id' and 'identity', but not both."
  }
}

variable "registry_username" {
  description = "(Required) The username to use to access the configured container registry."
  type        = string
}

variable "registry_server" {
  description = "(Required) The container registry server."
  type        = string
  default     = "ghcr.io"
}