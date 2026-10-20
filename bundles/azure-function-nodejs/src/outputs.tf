# An application bundle renders its resources from these outputs with a jq
# template on the `src` step. Example: `.outputs.default_hostname`.

output "function_app_name" {
  value = azurerm_function_app_flex_consumption.main.name
}

output "function_app_id" {
  value = azurerm_function_app_flex_consumption.main.id
}

output "default_hostname" {
  value = azurerm_function_app_flex_consumption.main.default_hostname
}

output "url" {
  value = "https://${azurerm_function_app_flex_consumption.main.default_hostname}"
}

output "resource_group" {
  value = azurerm_resource_group.main.name
}
