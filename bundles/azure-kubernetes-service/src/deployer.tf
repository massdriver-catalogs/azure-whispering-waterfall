# The Massdriver Helm provisioner authenticates with a bearer token. This
# service account holds that token. It has the cluster-admin role, because a
# Helm bundle can create namespaces and cluster-wide objects.

resource "kubernetes_service_account_v1" "deployer" {
  metadata {
    name      = "massdriver-deployer"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding_v1" "deployer" {
  metadata {
    name = "massdriver-deployer"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.deployer.metadata[0].name
    namespace = kubernetes_service_account_v1.deployer.metadata[0].namespace
  }
}

# A secret of this type makes Kubernetes issue a token that does not expire.
# To rotate the token, delete the secret and deploy again.
resource "kubernetes_secret_v1" "deployer" {
  metadata {
    name      = "massdriver-deployer-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.deployer.metadata[0].name
    }
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}
