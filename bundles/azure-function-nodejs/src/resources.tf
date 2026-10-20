# The packages container of the host storage account. The connection string
# holds a blob-only SAS that expires 30 days after the last deployment.
resource "massdriver_resource" "packages" {
  field = "packages"
  name  = "Packages ${local.name_prefix}"
  resource = jsonencode({
    id                = azurerm_storage_account.host.id
    name              = azurerm_storage_account.host.name
    container         = azurerm_storage_container.packages.name
    endpoint          = "${azurerm_storage_account.host.primary_blob_endpoint}${azurerm_storage_container.packages.name}"
    region            = azurerm_resource_group.main.location
    connection_string = "BlobEndpoint=${trimsuffix(azurerm_storage_account.host.primary_blob_endpoint, "/")};SharedAccessSignature=${trimprefix(data.azurerm_storage_account_sas.packages.sas, "?")}"
  })
}
