resource "massdriver_resource" "cluster" {
  field = "cluster"
  name  = "AKS ${var.md_metadata.name_prefix}"

  resource = jsonencode({
    id                  = azurerm_kubernetes_cluster.main.id
    name                = azurerm_kubernetes_cluster.main.name
    region              = azurerm_resource_group.main.location
    version             = azurerm_kubernetes_cluster.main.current_kubernetes_version
    resource_group      = azurerm_resource_group.main.name
    node_resource_group = azurerm_kubernetes_cluster.main.node_resource_group

    # This is the shape that the Massdriver Helm provisioner reads.
    authentication = {
      cluster = {
        server                     = azurerm_kubernetes_cluster.main.kube_config[0].host
        certificate-authority-data = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
      }
      user = {
        token = kubernetes_secret_v1.deployer.data["token"]
      }
    }
  })
}
