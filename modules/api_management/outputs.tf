
output "api_management_id" {
  value = azurerm_api_management.apim.id
}

output "gateway_url" {
  value = azurerm_api_management.apim.gateway_url
}