
output "virtual_network_name" {
  description = "Returns the name of the virtual network."
  value       = azurerm_virtual_network.network.name
}

output "virtual_network_id" {
  description = "Returns the ID of the virtual network."
  value       = azurerm_virtual_network.network.id
}

output "subnets" {
  description = "Returns a map of the subnet names to the subnet IDs."
  value       = { for s in keys(var.subnets) : s => azurerm_subnet.subnets[s].id }
}

output "nsg_ids" {
  description = "Returns a map of the network security group names to their IDs."
  value       = { for k, v in azurerm_network_security_group.nsgs : k => v.id }
}
