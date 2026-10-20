terraform {
  required_version = ">= 1.8"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.60"
    }
    massdriver = {
      source  = "massdriver-cloud/massdriver"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
  client_id       = var.azure_service_principal.client_id
  tenant_id       = var.azure_service_principal.tenant_id
  client_secret   = var.azure_service_principal.client_secret
  subscription_id = var.azure_service_principal.subscription_id
}

# The service principal that creates the workspace becomes a workspace admin.
# The provider signs in to the workspace with the same principal.
provider "databricks" {
  host                        = "https://${azurerm_databricks_workspace.main.workspace_url}"
  azure_workspace_resource_id = azurerm_databricks_workspace.main.id
  azure_client_id             = var.azure_service_principal.client_id
  azure_client_secret         = var.azure_service_principal.client_secret
  azure_tenant_id             = var.azure_service_principal.tenant_id
}
