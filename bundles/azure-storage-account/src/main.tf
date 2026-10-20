locals {
  name_prefix = var.md_metadata.name_prefix

  # Azure permits 3 to 24 lowercase letters and digits in a storage account
  # name, and the name is global to Azure. The bundle removes the hyphens of
  # the Massdriver prefix, truncates it to 18 characters, and adds 6 random
  # characters.
  account_name = "${substr(replace(lower(local.name_prefix), "/[^a-z0-9]/", ""), 0, 18)}${random_string.suffix.result}"
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
  access_tier              = var.access_tier

  # Security defaults. A developer cannot weaken these from the form.
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true
  local_user_enabled                = false
  sftp_enabled                      = false

  # Applications connect with the connection string that the resource carries.
  # The connection string needs the shared access key.
  shared_access_key_enabled = true

  # The applications of this catalog run outside a virtual network, so the
  # account accepts traffic from the public endpoint. Every request still needs
  # the key, and no container is public.
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  blob_properties {
    versioning_enabled = var.versioning_enabled

    delete_retention_policy {
      days = var.retention_days
    }

    container_delete_retention_policy {
      days = var.retention_days
    }
  }

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "main" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}
