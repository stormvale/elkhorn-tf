
output "virtual_network_name" {
  description = "Returns the name of the virtual network."
  value       = azurerm_virtual_network.network.name
}

output "virtual_network_id" {
  description = "Returns the ID of the virtual network."
  value       = azurerm_virtual_network.network.id
}

output "subnet_ids" {
  description = "Returns a map of the subnet names to the subnet IDs."
  value       = { for s in keys(var.subnets) : s => azurerm_subnet.subnet[s].id }
}