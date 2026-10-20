locals {
  name_prefix = var.md_metadata.name_prefix

  # Azure permits 3 to 24 lowercase letters and digits in a storage account
  # name, and the name is global to Azure.
  host_account_name = "${substr(replace(lower(local.name_prefix), "/[^a-z0-9]/", ""), 0, 18)}${random_string.suffix.result}"

  # Package URL is an HTTPS URL, or the name of a blob in the `packages`
  # container of the host storage account.
  has_package     = var.package_url != ""
  package_is_url  = startswith(var.package_url, "https://")
  package_url     = local.package_is_url ? var.package_url : "${azurerm_storage_account.host.primary_blob_endpoint}${azurerm_storage_container.packages.name}/${var.package_url}${data.azurerm_storage_account_blob_container_sas.package_read.sas}"
  packages_expiry = timeadd(plantimestamp(), "720h")
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

resource "azurerm_log_analytics_workspace" "main" {
  count               = var.application_insights ? 1 : 0
  name                = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.md_metadata.default_tags
}

resource "azurerm_application_insights" "main" {
  count               = var.application_insights ? 1 : 0
  name                = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  workspace_id        = azurerm_log_analytics_workspace.main[0].id
  application_type    = "Node.JS"
  tags                = var.md_metadata.default_tags
}

# The host storage account holds the deployment package, the trigger state,
# the keys of the Function host, the uploaded packages, and the function logs.
# No application data goes here.
resource "azurerm_storage_account" "host" {
  name                = local.host_account_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.md_metadata.default_tags

  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "deployments" {
  name                  = "deployments"
  storage_account_id    = azurerm_storage_account.host.id
  container_access_type = "private"
}

# An operator uploads zip packages here. Package URL can name one of them.
resource "azurerm_storage_container" "packages" {
  name                  = "packages"
  storage_account_id    = azurerm_storage_account.host.id
  container_access_type = "private"
}

# A blob-only SAS for the host account. The runtime reads the package with it,
# and the `packages` resource gives it to an operator for uploads and logs.
data "azurerm_storage_account_sas" "packages" {
  connection_string = azurerm_storage_account.host.primary_connection_string
  https_only        = true
  signed_version    = "2022-11-02"
  start             = timeadd(plantimestamp(), "-1h")
  expiry            = local.packages_expiry

  resource_types {
    service   = false
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  permissions {
    read    = true
    write   = true
    delete  = false
    list    = true
    add     = true
    create  = true
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

resource "azurerm_service_plan" "main" {
  name                = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "FC1"
  tags                = var.md_metadata.default_tags
}

# A read-only SAS for the packages container. It expires two hours after the
# plan, and it is only used for the copy below.
data "azurerm_storage_account_blob_container_sas" "package_read" {
  connection_string = azurerm_storage_account.host.primary_connection_string
  container_name    = azurerm_storage_container.packages.name
  https_only        = true
  start             = timeadd(plantimestamp(), "-1h")
  expiry            = timeadd(plantimestamp(), "2h")

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}

# The Flex Consumption host runs the package in deployments/released-package.zip.
# Azure Storage copies the package on the server side, so the bundle runs no
# local commands. A new value of Package URL replaces the blob.
resource "terraform_data" "package_url" {
  input = var.package_url
}

# An earlier development release wrote the package to a local file. OpenTofu
# forgets that file and does not try to destroy it.
removed {
  from = local_sensitive_file.package

  lifecycle {
    destroy = false
  }
}

resource "azurerm_storage_blob" "package" {
  count                = local.has_package ? 1 : 0
  name                 = "released-package.zip"
  storage_container_id = azurerm_storage_container.deployments.id
  type                 = "Block"
  content_type         = "application/zip"
  source_uri           = sensitive(local.package_url)

  lifecycle {
    # The SAS in the source URI changes on each plan. Only a new package
    # replaces the blob.
    ignore_changes       = [source_uri]
    replace_triggered_by = [terraform_data.package_url]
  }
}

resource "azurerm_function_app_flex_consumption" "main" {
  name                = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  tags                = var.md_metadata.default_tags

  runtime_name    = "node"
  runtime_version = "22"

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.host.primary_blob_endpoint}${azurerm_storage_container.deployments.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.host.primary_access_key

  instance_memory_in_mb  = var.instance_memory_mb
  maximum_instance_count = var.maximum_instance_count

  https_only = true

  # The application envs and secrets become app settings. The settings of the
  # runtime come last, so an application cannot replace them.
  app_settings = merge(
    local.app_settings_from_app,
    {
      AzureWebJobsStorage = azurerm_storage_account.host.primary_connection_string
      # A new package changes this setting, and the change restarts the app.
      MD_PACKAGE = local.has_package ? "${var.package_url}#${azurerm_storage_blob.package[0].id}" : ""
    },
  )

  site_config {
    application_insights_connection_string = var.application_insights ? azurerm_application_insights.main[0].connection_string : null
    minimum_tls_version                    = "1.2"
    scm_minimum_tls_version                = "1.2"
  }

  identity {
    type = "SystemAssigned"
  }
}

# A copied package does not tell the Flex scale controller about its triggers.
# This ARM call syncs the triggers on each deployment, so a queue trigger
# starts an instance when a message arrives.
resource "terraform_data" "sync_triggers" {
  count = local.has_package ? 1 : 0
  input = plantimestamp()
}

resource "azapi_resource_action" "sync_triggers" {
  count       = local.has_package ? 1 : 0
  type        = "Microsoft.Web/sites@2024-04-01"
  resource_id = azurerm_function_app_flex_consumption.main.id
  action      = "syncfunctiontriggers"
  method      = "POST"

  retry = {
    error_message_regex = ["BadRequest", "NotFound", "Conflict"]
  }

  depends_on = [azurerm_storage_blob.package]

  lifecycle {
    replace_triggered_by = [terraform_data.sync_triggers]
  }
}

# The function logs also go to the host storage account, in the container
# insights-logs-functionapplogs. An operator reads them with the SAS of the
# `packages` resource.
resource "azurerm_monitor_diagnostic_setting" "function_logs" {
  name               = "function-logs"
  target_resource_id = azurerm_function_app_flex_consumption.main.id
  storage_account_id = azurerm_storage_account.host.id

  enabled_log {
    category = "FunctionAppLogs"
  }
}
