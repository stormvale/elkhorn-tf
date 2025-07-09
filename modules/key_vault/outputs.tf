
output "key_vault_id" {
  description = "The ID of the key vault."
  value       = azurerm_key_vault.vault.id
}

output "key_vault_name" {
  description = "The name of the key vault."
  value       = azurerm_key_vault.vault.name
}

output "key_vault_uri" {
  description = "The uri of the key vault."
  value       = azurerm_key_vault.vault.vault_uri
}

output "secret_ids" {
  description = "Map of secret names to their Azure resource IDs (ie. full URIs)."
  value = {
    for name, secret in azurerm_key_vault_secret.secrets :
    name => secret.id
  }
}

# eg. { "DB_PASSWORD" = ".../secrets/db-password/..." }
output "env_secret_mapping" {
  description = "Possibly useful for injecting secrets via ENV variables."
  value = {
    for name, secret in azurerm_key_vault_secret.secrets :
    upper(name) => secret.id
  }
}
