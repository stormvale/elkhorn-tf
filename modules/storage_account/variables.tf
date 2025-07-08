variable "resource_group_name" {
  description = "(Required) The name of the resource group where the resource should exist."
  type        = string
}

variable "location" {
  description = "(Required) Azure region where the resource should exist"
  type        = string
}

variable "environment" {
  description = "(Required) The environment of the resource. Valid options are 'development' and 'production'."
  type        = string

  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "Allowed values for environment are \"development\", \"production\"."
  }
}

variable "name" {
  description = "(Required) The name of the resource."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource. Tags for 'environment' and 'managedby' are automatically assigned."
  type        = map(string)
  default     = {}
}

variable "account_tier" {
  description = "The Tier of the storage account. Valid options are Standard and Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Allowed values for account_tier are \"Standard\", \"Premium\"."
  }
}

variable "account_replication_type" {
  description = "The Replication Type for the storage account. Valid options include LRS, GRS, ZRS etc."
  type        = string
  default     = "LRS"
}

variable "containers" {
  description = "(Optional) List of storage containers to create in the storage account."
  type        = set(string)
  default     = []
}