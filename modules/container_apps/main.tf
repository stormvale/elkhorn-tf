
resource "azurerm_container_app" "apps" {
  for_each = var.container_apps

  name                         = "ca-${each.key}-${local.name_suffix}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = "Single"
  tags                         = var.tags

  lifecycle {
    ignore_changes = [
      secret,                        # don't recreate this resource when key vault secrets change
      template[0].container[0].image # don't reset image if manually deployed (eg. pr, other tag)
    ]
  }

  template {
    container {
      name   = each.key
      image  = each.value.image
      cpu    = each.value.cpu
      memory = each.value.memory

      dynamic "env" {
        for_each = { for v in each.value.environment_variables : v.name => v }
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }
    }

    min_replicas = 0
    max_replicas = 1

    # other scale rule types available
    http_scale_rule {
      name                = "increased-http-traffic"
      concurrent_requests = "100"
    }
  }

  ingress {
    external_enabled = each.value.ingress_enabled
    target_port      = 8080
    transport        = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [var.container_apps_identity_id]
  }

  dynamic "secret" {
    for_each = each.value.secrets
    content {
      name                = secret.value.name
      value               = secret.value.value
      identity            = var.container_apps_identity_id
      key_vault_secret_id = secret.value.key_vault_secret_id
    }
  }

  registry {
    server               = "ghcr.io"
    username             = var.registry_username
    password_secret_name = "gh-pat-secret"
  }

  dapr {
    app_id       = "${each.key}-api"
    app_port     = 8080
    app_protocol = "http"
  }
}

# TODO: move all the dapr components stuff out into their own module and configure each component separately
resource "azurerm_container_app_environment_dapr_component" "components" {
  for_each = { for c in nonsensitive(var.dapr_components) : c.name => c }

  name                         = each.key
  container_app_environment_id = var.container_app_environment_id
  component_type               = each.value.component_type
  scopes                       = each.value.scopes
  version                      = "v1"

  dynamic "metadata" {
    for_each = each.value.metadata != null ? each.value.metadata : []
    content {
      name        = metadata.value.name
      value       = metadata.value.value
      secret_name = metadata.value.secret_name
    }
  }

  dynamic "secret" {
    for_each = each.value.secret != null ? each.value.secret : []
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }
}

resource "azurerm_servicebus_topic" "topics" {
  for_each             = var.container_apps
  name                 = "${each.key}-events"
  namespace_id         = var.servicebus_namespace_id
  partitioning_enabled = false
}