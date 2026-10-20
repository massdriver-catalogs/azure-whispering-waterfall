locals {
  name_prefix = var.md_metadata.name_prefix
  has_landing = try(var.landing.connection_string, null) != null
}

resource "azurerm_resource_group" "main" {
  name     = local.name_prefix
  location = var.region
  tags     = var.md_metadata.default_tags
}

# The workspace has no cost until a cluster or a SQL warehouse runs. The bundle
# starts no compute. The Premium tier is necessary for access control on the
# secret scope.
resource "azurerm_databricks_workspace" "main" {
  name                        = local.name_prefix
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  sku                         = "premium"
  managed_resource_group_name = "${local.name_prefix}-managed"
  tags                        = var.md_metadata.default_tags

  # Clusters get no public IP address. The control plane reaches them through
  # secure cluster connectivity.
  custom_parameters {
    no_public_ip = true
  }
}

# A notebook reads the landing container with these values:
#   dbutils.secrets.get("landing", "connection-string")
resource "databricks_secret_scope" "landing" {
  count = local.has_landing ? 1 : 0
  name  = "landing"
}

resource "databricks_secret" "landing" {
  for_each = local.has_landing ? {
    "connection-string" = var.landing.connection_string
    "account-name"      = var.landing.name
    "container"         = var.landing.container
  } : {}

  scope        = databricks_secret_scope.landing[0].id
  key          = each.key
  string_value = each.value
}

resource "databricks_notebook" "landing" {
  count    = local.has_landing ? 1 : 0
  path     = "/Shared/orders/read_landing"
  language = "PYTHON"
  source   = "${path.module}/notebooks/read_landing.py"
}
