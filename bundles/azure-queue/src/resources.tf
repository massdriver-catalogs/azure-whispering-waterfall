resource "massdriver_resource" "queue" {
  field = "queue"
  name  = "Storage Queue ${var.md_metadata.name_prefix}"

  resource = jsonencode({
    id                = azurerm_storage_queue.main.id
    name              = azurerm_storage_queue.main.name
    account_name      = azurerm_storage_account.main.name
    account_id        = azurerm_storage_account.main.id
    queue_url         = "${azurerm_storage_account.main.primary_queue_endpoint}${azurerm_storage_queue.main.name}"
    poison_queue_name = azurerm_storage_queue.poison.name
    region            = azurerm_resource_group.main.location
    connection_string = azurerm_storage_account.main.primary_connection_string
  })
}
