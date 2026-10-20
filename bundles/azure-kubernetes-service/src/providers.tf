terraform {
  required_version = ">= 1.8"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
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

# The bundle connects to the new cluster with the admin certificate of the
# cluster. It uses the connection only to create the deployer token.
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.main.kube_config[0].host
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate)
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].client_key)
}
