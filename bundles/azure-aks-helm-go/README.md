# Azure AKS Helm Runtime for Go

A runtime bundle for Go services on Azure Kubernetes Service. It deploys a
Helm chart with one Deployment, one ClusterIP Service, and one Secret. An
application bundle sets `app.runtime: azure-aks-helm-go@<constraint>` and
extends this runtime. Do not deploy this runtime as a component.

## Defaults for Go

- The container listens on port 8080 and answers `GET /healthz`.
- The pod runs as user 65532 (the `nonroot` user of the distroless images) with
  a read-only root file system.
- The pod requests 50m of processor and 64 MiB of memory.

## What an application bundle adds

| Item | How |
|---|---|
| Dependencies | `dependencies:` in the application `massdriver.yaml`. |
| Environment variables | `app.envs:` jq expressions. Each one becomes a container environment variable. |
| Secrets | `app.secrets:`. Each one goes into the Secret of the release. |
| Connection strings | Automatic. A connected dependency with a `connection_string` field becomes the secret variable `<DEPENDENCY NAME>_CONNECTION_STRING`. |
| Resources | `resources:` and a jq template on the `chart` step. Use `.params.md_metadata.name_prefix` (the release name and the service name) and `.params.namespace`. |

## Service address

The service name is the instance name. Inside the cluster, the address is
`http://<instance name>.<namespace>.svc.cluster.local`.
