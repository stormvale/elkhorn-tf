variable "location" {
  description = "Azure region where the resources should exist"
  type        = string
  default     = "westus2"
}

variable "location_map" {
  description = "Maps a long location name to a short code. Used in resource names."
  type        = map(string)
  default = {
    "westus2"       = "wus2",
    "canadacentral" = "cnc"
  }
}

locals {
  location_short    = lookup(var.location_map, var.location)
  name_suffix       = "elkhorn-${local.location_short}"
}