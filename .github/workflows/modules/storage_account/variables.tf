variable resource_group_name {}

variable "location" {
  description = "Azure region where the storage account should exist"
  type        = string
}

variable environment {
  description = "The environment of the storage account. Valid options are 'development' and 'production'."
  type = string

  validation {
    condition     = contains(["development", "production"], var.input_parameter)
    error_message = "Allowed values for input_parameter are \"development\", \"production\"."
  }
}

variable name {
  description = "The name of the storage account."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the storage account. Tags for 'env' and 'managedby' are automatically assigned."
  type        = map(string)
  default     = []
}

variable account_tier {
  description = "The Tier of the storage account. Valid options are Standard and Premium."
  type = string
  default = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.input_parameter)
    error_message = "Allowed values for input_parameter are \"Standard\", \"Premium\"."
  }
}

variable replication_type {
  description = "The Replication Type for the storage account. Valid options include LRS, GRS, ZRS etc."
  type        = string
  default     = "LRS"
}