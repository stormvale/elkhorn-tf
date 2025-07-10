
output "container_app_urls" {
  value = {
    for app_key, app_resource in azurerm_container_app.apps :
    app_key => "https://${app_resource.ingress[0].fqdn}" # requires ingress block to be defined
  }
}

