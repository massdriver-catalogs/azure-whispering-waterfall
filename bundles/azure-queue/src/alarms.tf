# Azure Monitor metrics for the storage account of the queue.

resource "massdriver_instance_alarm" "availability" {
  display_name        = "Queue availability below 99 percent"
  cloud_resource_id   = "${azurerm_storage_account.main.id}/queueServices/default|availability"
  threshold           = 99
  period              = 300
  comparison_operator = "LessThanThreshold"

  metric {
    name      = "Availability"
    namespace = "Microsoft.Storage/storageAccounts/queueServices"
    statistic = "Average"
    region    = azurerm_resource_group.main.location
  }
}
