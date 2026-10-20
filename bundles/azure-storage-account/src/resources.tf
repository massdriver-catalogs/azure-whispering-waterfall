resource "massdriver_resource" "bucket" {
  field = "bucket"
  name  = "Blob Storage ${var.md_metadata.name_prefix}"

  resource = jsonencode({
    id                = azurerm_storage_account.main.id
    name              = azurerm_storage_account.main.name
    container         = azurerm_storage_container.main.name
    endpoint          = "${azurerm_storage_account.main.primary_blob_endpoint}${azurerm_storage_container.main.name}"
    region            = azurerm_resource_group.main.location
    connection_string = azurerm_storage_account.main.primary_connection_string
  })
}
