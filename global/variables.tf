variable "location" {
  description = "Azure region where the resources should exist"
  type        = string
  default     = "westus2"
}

variable "location_short" {
  description = "Short prefix for location"
  type        = map(string)
  default = {
    westus2       = "wus2",
    canadacentral = "cnc"
  }
}

variable "app_name" {
  description = "The application name to use for naming resources"
  type        = string
  default     = "elkhorn"
}

locals {
  location-short = lookup(var.location_short, var.location)
}