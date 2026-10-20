# Azure Monitor metrics for the Function app.

resource "massdriver_instance_alarm" "http_5xx" {
  display_name        = "HTTP 5xx responses"
  cloud_resource_id   = "${azurerm_function_app_flex_consumption.main.id}|http5xx"
  threshold           = 5
  period              = 300
  comparison_operator = "GreaterThanThreshold"

  metric {
    name      = "Http5xx"
    namespace = "Microsoft.Web/sites"
    statistic = "Total"
    region    = azurerm_resource_group.main.location
  }
}
