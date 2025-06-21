
output "id" {
  description = "The ID of the Azure Container Apps Environment"
  value       = azurerm_container_app_environment.cae.id
}

output "location" {
  description = "The location of the Azure Container Apps Environment"
  value       = azurerm_container_app_environment.cae.location
}

output "subnet_id" {
  description = "The ID of the subnet used by the Container Apps Control Plan (infrastructure)"
  value       = azurerm_subnet.cae_subnet.id
}