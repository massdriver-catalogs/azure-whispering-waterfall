# The runtime installs the local chart in ../chart with the Helm provider.
# OpenTofu outputs are an object, so an application bundle can emit resources
# with a jq template on the src step (.outputs.name, .outputs.namespace,
# .outputs.url). The Helm provisioner cannot do this: its outputs are a list.
terraform {
  required_version = ">= 1.6"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

locals {
  auth = var.kubernetes_cluster.authentication

  # The release name and the Service name.
  name = var.md_metadata.name_prefix

  # The provisioner writes the rendered app envs, the app secrets, and all of
  # the dependencies to these files. The application bundle adds to them, so
  # the runtime reads the files and not the variables. The files exist only in
  # the provisioner. try() lets tofu validate run on a workstation.
  envs         = jsondecode(try(file("/massdriver/envs.json"), "{}"))
  secrets      = jsondecode(try(file("/massdriver/secrets.json"), "{}"))
  dependencies = jsondecode(try(file("/massdriver/dependencies.json"), "{}"))

  # Each dependency with a connection string becomes the secret variable
  # <DEPENDENCY NAME>_CONNECTION_STRING.
  connection_strings = {
    for name, dep in local.dependencies :
    "${upper(name)}_CONNECTION_STRING" => dep.connection_string
    if can(dep.connection_string)
  }
}

provider "helm" {
  kubernetes {
    host                   = local.auth.cluster.server
    cluster_ca_certificate = base64decode(local.auth.cluster["certificate-authority-data"])
    token                  = local.auth.user.token
  }
}

resource "helm_release" "app" {
  name             = local.name
  chart            = "${path.module}/../chart"
  namespace        = var.namespace
  create_namespace = true
  wait             = true
  timeout          = 300

  # The secrets go in a second values document. sensitive() keeps them out of
  # the plan output.
  values = [
    yamlencode({
      image             = var.image
      replicas          = var.replicas
      port              = var.port
      health_check_path = var.health_check_path
      cpu               = var.cpu
      memory            = var.memory
      envs              = local.envs
    }),
    sensitive(yamlencode({
      secrets = merge(local.connection_strings, local.secrets)
    })),
  ]
}

output "name" {
  value = helm_release.app.name
}

output "namespace" {
  value = helm_release.app.namespace
}

output "url" {
  value = "http://${helm_release.app.name}.${helm_release.app.namespace}.svc.cluster.local"
}
