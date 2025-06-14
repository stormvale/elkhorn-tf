
variable "docker_registry_username" {
  description = "(Required) GitHub username to access the GitHub Container Registry"
  type        = string
}

variable "docker_registry_password" {
  description = "(Required) GitHub password to access the GitHub Container Registry"
  type        = string
  sensitive   = true
  ephemeral   = true # don't save in plan
}

variable "location" {
  description = "Azure region where the resources should exist"
  type        = string
  default     = "westus2"
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
  environment_short = lookup(var.environment_map, "development")
  name_suffix       = "elkhorn-${local.environment_short}-${local.location_short}"
}