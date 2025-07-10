
resource "azurerm_servicebus_namespace" "sb" {
  name                = "sbns-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard" # Basic tier doesn't include topics
}

resource "azurerm_servicebus_namespace_authorization_rule" "dapr_pubsub" {
  name         = "dapr-pubsub-access"
  namespace_id = azurerm_servicebus_namespace.sb.id

  manage = true # needed by dapr to create & manage subscriptions to the topic
  listen = true
  send   = true
}

# a topic for each microservice is created in the container_apps module.
# in the future we may create more general topics or queues here.
