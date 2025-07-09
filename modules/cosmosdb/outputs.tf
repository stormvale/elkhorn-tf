output "id" {
  value = azurerm_cosmosdb_account.account.id
}

output "name" {
  value = azurerm_cosmosdb_account.account.name
}

output "account_connection_string" {
  description = "The primary connection string for the Cosmos DB account."
  value       = azurerm_cosmosdb_account.account.primary_sql_connection_string
  sensitive   = true
}

output "principal_id" {
  value = azurerm_cosmosdb_account.account.identity[0].principal_id
}