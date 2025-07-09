
output "id" {
  value = azurerm_servicebus_namespace.sb.id
}

output "dapr_access_connection_string" {
  description = "Primary Connection String for the dapr-pubsub Shared Access Policy (Send, Listen)"
  value       = azurerm_servicebus_namespace_authorization_rule.dapr_pubsub.primary_connection_string
}