variable "resource_group_name" {
  description = "(Required) The name of the resource group where the resource should exist."
  type        = string
}

variable "location" {
  description = "(Required) The Azure region where the resource should exist"
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
  type        = map(string)
  description = "(Optional) Name and address space for subnets, defaults to subnet1 and 10.0.0.0/24."
  default     = { subnet1 = "10.0.0.0/24" }
}

variable "tags" {
  description = "A map of tags to assign to the resource. Tags for 'environment' and 'managedby' are automatically assigned."
  type        = map(string)
  default     = {}
}