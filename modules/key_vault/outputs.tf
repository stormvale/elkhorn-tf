
output "key_vault_id" {
  description = "The ID of the key vault."
  value       = azurerm_key_vault.vault.id
}

output "key_vault_uri" {
  description = "The uri of the key vault."
  value       = azurerm_key_vault.vault.vault_uri
}