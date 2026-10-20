locals {
  name_prefix = var.md_metadata.name_prefix

  # Azure permits 3 to 24 lowercase letters and digits in a storage account
  # name, and the name is global to Azure.
  account_name = "${substr(replace(lower(local.name_prefix), "/[^a-z0-9]/", ""), 0, 18)}${random_string.suffix.result}"

  # The Azure Functions queue trigger moves a failed message to this queue.
  poison_queue_name = "${var.queue_name}-poison"
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "main" {
  name     = local.name_prefix
  location = var.region
  tags     = var.md_metadata.default_tags
}

resource "azurerm_storage_account" "main" {
  name                = local.account_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.md_metadata.default_tags

  account_tier             = "Standard"
  account_replication_type = replace(var.redundancy, "Standard_", "")
  account_kind             = "StorageV2"

  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true
  local_user_enabled                = false
  sftp_enabled                      = false

  # Producers and consumers connect with the connection string that the
  # resource carries. The connection string needs the shared access key.
  shared_access_key_enabled = true

  # The applications of this catalog run outside a virtual network.
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
}

# Checkov CKV_AZURE_33 asks for a log of every queue request.
resource "azurerm_storage_account_queue_properties" "main" {
  storage_account_id = azurerm_storage_account.main.id

  logging {
    version               = "1.0"
    delete                = true
    read                  = true
    write                 = true
    retention_policy_days = 7
  }
}

resource "azurerm_storage_queue" "main" {
  name               = var.queue_name
  storage_account_id = azurerm_storage_account.main.id
}

resource "azurerm_storage_queue" "poison" {
  name               = local.poison_queue_name
  storage_account_id = azurerm_storage_account.main.id
}
