locals {
  name_prefix = var.md_metadata.name_prefix

  # Azure permits 3 to 24 lowercase letters and digits in a storage account
  # name, and the name is global to Azure.
  host_account_name = "${substr(replace(lower(local.name_prefix), "/[^a-z0-9]/", ""), 0, 18)}${random_string.suffix.result}"

  has_package = var.package_url != ""
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
  name                = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.md_metadata.default_tags
}

resource "azurerm_application_insights" "main" {
  name                = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "Node.JS"
  tags                = var.md_metadata.default_tags
}

# The host storage account holds the deployment package, the trigger state,
# and the keys of the Function host. No application data goes here.
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
}

resource "azurerm_storage_container" "deployments" {
  name                  = "deployments"
  storage_account_id    = azurerm_storage_account.host.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "main" {
  name                = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "FC1"
  tags                = var.md_metadata.default_tags
}

# The package comes from an HTTPS URL. The bundle downloads it, writes it next
# to the code, and gives it to the zip deployment of the Function app. The file
# name holds the hash of the package, so a new package starts a new deployment.
data "http" "package" {
  count = local.has_package ? 1 : 0
  url   = var.package_url

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "The package URL did not return HTTP 200. Make sure that Azure can read the URL without a sign-in."
    }
  }
}

resource "local_sensitive_file" "package" {
  count          = local.has_package ? 1 : 0
  filename       = "${path.module}/package-${sha256(data.http.package[0].response_body_base64)}.zip"
  content_base64 = data.http.package[0].response_body_base64
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

  https_only      = true
  zip_deploy_file = local.has_package ? local_sensitive_file.package[0].filename : null

  # The order of the merge sets the precedence. A secret of the application
  # wins over an environment variable with the same name.
  app_settings = merge(
    local.app_envs,
    local.connection_strings,
    local.app_secrets,
    {
      AzureWebJobsStorage = azurerm_storage_account.host.primary_connection_string
    },
  )

  site_config {
    application_insights_connection_string = azurerm_application_insights.main.connection_string
    minimum_tls_version                    = "1.2"
    scm_minimum_tls_version                = "1.2"
  }

  identity {
    type = "SystemAssigned"
  }
}
