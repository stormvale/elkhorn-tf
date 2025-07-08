
resource "azurerm_container_app" "apps" {
  for_each = var.container_apps

  name                         = each.key
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  location                     = var.location
  revision_mode                = "Single"

  template {
    container {
      name   = each.key
      image  = each.value.image
      cpu    = each.value.cpu
      memory = each.value.memory

      dynamic "env" {
        for_each = each.value.environment_variables
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }

    }

    min_replicas = 0
    max_replicas = 2
  }

  ingress {
    external_enabled = each.value.ingress_enabled
    target_port      = 80
    traffic_weight {
      percentage = 100
    }
  }

  identity {
    type = "SystemAssigned"
  }

  dynamic "secret" {
    for_each = each.value.secrets
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }

  registry {
    server               = var.registry_server
    username             = var.registry_username
    password_secret_name = "gh-pat-secret"
  }

  lifecycle {
    ignore_changes = [secret] # reccommended when using key_vault_secret_id
  }

  tags = {
    environment = "development"
    managedby   = "terraform"
  }
}


# resource "azurerm_container_app" "api_weather" {
#   name                         = "api-weather-${local.name_suffix}"
#   container_app_environment_id = azurerm_container_app_environment.cae.id
#   resource_group_name          = azurerm_resource_group.rg.name
#   revision_mode                = "Single"

#   template {
#     container {
#       name   = "api-weather" # lower case alphanumeric characters or '-'. max 63 chars
#       image  = "ghcr.io/stormvale/api.weather:latest"
#       cpu    = 0.25
#       memory = "0.5Gi"

#       env { # environment variables can refer to secrets
#         name        = "ConnectionStrings__postgres"
#         secret_name = "conn-string-db"
#       }
#     }

#     # init_container { <ef migrations> }
#   }

#   identity {
#     type         = "SystemAssigned, UserAssigned"
#     identity_ids = [azurerm_user_assigned_identity.api_weather_id.id]
#   }

#   ingress {
#     external_enabled = true
#     target_port      = 8080
#     transport        = "http"

#     traffic_weight {
#       latest_revision = true
#       percentage      = 100
#     }
#   }

#   secret {
#     name                = "gh-pat-secret"
#     identity            = azurerm_user_assigned_identity.api_weather_id.id
#     key_vault_secret_id = data.azurerm_key_vault_secret.github_pat.versionless_id
#     # per docs: When using key_vault_secret_id, ignore_changes should be used to ignore any changes to value. (see lifecycle)
#   }

#   secret {
#     name  = "conn-string-db"
#     value = "<db connection string goes here>"
#   }

#   registry {
#     server               = "ghcr.io"
#     username             = var.registry_username
#     password_secret_name = "gh-pat-secret"
#   }

#   lifecycle {
#     ignore_changes = [secret]
#   }

#   tags = {
#     environment = "development"
#     managedby   = "terraform"
#   }
# }