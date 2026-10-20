resource "massdriver_resource" "workspace" {
  field = "workspace"
  name  = "Databricks ${var.md_metadata.name_prefix}"

  resource = jsonencode({
    id                     = azurerm_databricks_workspace.main.id
    name                   = azurerm_databricks_workspace.main.name
    region                 = azurerm_resource_group.main.location
    workspace_id           = azurerm_databricks_workspace.main.workspace_id
    workspace_url          = "https://${azurerm_databricks_workspace.main.workspace_url}"
    managed_resource_group = azurerm_databricks_workspace.main.managed_resource_group_name
  })
}
