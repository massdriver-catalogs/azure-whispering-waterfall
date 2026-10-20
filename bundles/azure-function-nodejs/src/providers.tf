terraform {
  required_version = ">= 1.8"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.30"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    massdriver = {
      source  = "massdriver-cloud/massdriver"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {
    # Application Insights creates a "Failure Anomalies" alert rule outside of
    # OpenTofu. Without this, the resource group delete fails on decommission.
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  client_id       = var.azure_service_principal.client_id
  tenant_id       = var.azure_service_principal.tenant_id
  client_secret   = var.azure_service_principal.client_secret
  subscription_id = var.azure_service_principal.subscription_id
}

provider "azapi" {
  client_id       = var.azure_service_principal.client_id
  tenant_id       = var.azure_service_principal.tenant_id
  client_secret   = var.azure_service_principal.client_secret
  subscription_id = var.azure_service_principal.subscription_id
}
