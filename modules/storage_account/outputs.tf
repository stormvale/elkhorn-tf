output "id" {
  value = azurerm_storage_account.storage.id
}

output "name" {
  value = azurerm_storage_account.storage.name
}

output "primary_access_key" {
  value     = azurerm_storage_account.storage.primary_access_key
  sensitive = true
}

output "primary_connection_string" {
  value = azurerm_storage_account.storage.primary_connection_string
}

output "container_names" {
  description = "List of created storage container names."
  value       = [for c in azurerm_storage_container.containers : c.name]
}
