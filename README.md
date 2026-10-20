# Azure Event-Driven Catalog

A Massdriver catalog of Azure bundles, resource types, and application runtimes
for event-driven services. Publish it to your organization, deploy the two
example projects, and watch applications pass resources to each other on the
canvas: a Function app hands its URL to a service on AKS, the AKS service writes
to a queue, and a second Function app consumes that queue.

Contents: 5 infrastructure bundles, 2 runtimes, 3 application bundles, 8
resource types, and the Azure service principal credential type.

This catalog is derived from the
[Massdriver Azure catalog](https://github.com/massdriver-catalogs/azure). It
keeps the network, Kubernetes, and storage bundles from there, adds queue and
Databricks bundles, and adds two application runtimes with apps that extend
them.

## Concepts

| Term | Meaning |
|---|---|
| Resource type | A JSON Schema contract describing what one component passes to another, such as a queue's name and connection string. Massdriver validates connections against it. |
| Bundle | A versioned package of IaC (OpenTofu or Helm) with the schema of its inputs, the resources it produces, and its documentation. |
| Runtime | A bundle that sets `provides: [runtime]`. It owns the IaC, the params, and the UI for one way of running code, such as Node.js on Azure Functions. |
| Application bundle | A small bundle that sets `app.runtime: <runtime>@<constraint>`. It adds its own dependencies, environment variables, secrets, and resources on top of the runtime, and carries no IaC of its own. |
| Resource | The output of a deployed bundle. The queue bundle emits an `azure-storage-queue` resource with the queue name and its connection string. |
| Project | A group of related infrastructure. Components are added at the project level. |
| Environment | A deployment context inside a project, such as `dev` or `prod`. Each environment gets one instance of every component in the project. |
| Instance | One configured, deployed copy of a bundle in one environment. |

## Architecture

The catalog is designed around two projects. A platform project owns the shared
network and cluster. An application project holds the data services and the
apps, and reaches the cluster through a remote reference.

```
Platform project
  azure-network (azure-vnet) ──▶ azure-aks (azure-kubernetes-service)
                                        │
                                        │ remote reference
                                        ▼
Application project
  azure-api ─────────────▶ azure-processor ──▶ azure-events ──▶ azure-worker
  (Function, Node.js)       (AKS, Go)           (queue)          (Function, Node.js)
                                │                                    ▲
                                ▼                                    │
                           azure-receipts                       azure-lakehouse
                           (blob storage)                       (Databricks)
                                                                     ▲
                                                azure-landing ───────┘
                                                (blob storage)
```

- `azure-api` emits an `azure-orders-api-service` resource with its URL.
  `azure-processor` consumes it, so the processor gets the API URL as an
  environment variable.
- `azure-processor` writes order events to the `azure-events` queue and
  receipts to `azure-receipts`.
- `azure-worker` reads the `azure-events` queue with a queue trigger. It also
  consumes the Databricks workspace resource and gets the workspace URL as an
  environment variable.
- `azure-landing` feeds `azure-lakehouse`, which stores the container
  connection in a Databricks secret scope and adds a notebook that reads it.

## Bundles

Infrastructure:

| Bundle | Creates | Emits |
|---|---|---|
| `azure-vnet` | A resource group, a VNet, delegated subnets, and a network security group per subnet. | `azure-virtual-network` |
| `azure-kubernetes-service` | An AKS cluster in the connected network with autoscaling, and a deployer service account and token for Helm releases. | `azure-aks-cluster` |
| `azure-storage-account` | A storage account and one blob container. | `azure-blob-storage` |
| `azure-queue` | A storage account, a queue, and its poison queue. | `azure-storage-queue` |
| `azure-databricks` | A Databricks workspace with no compute, a secret scope for the connected landing container, and a notebook that reads it. | `azure-databricks-workspace` |

Runtimes:

| Runtime | Runs | How it deploys |
|---|---|---|
| `azure-function-nodejs` | Node.js 22 (TypeScript) Function apps on the Flex Consumption plan. | Creates the plan, the Function app, a host storage account, and Application Insights. Code ships as a zip: the runtime emits a private `packages` container, and the `package_url` param names the blob to deploy. Azure Storage copies the package server-side, so no local commands run during a deployment. |
| `azure-aks-helm-go` | Go services on the connected AKS cluster. | Installs a local Helm chart (Deployment, Service, Secret) with `helm_release` from an OpenTofu step. App environment variables become container env vars, and every connected resource with a `connection_string` becomes a `<NAME>_CONNECTION_STRING` secret. |

Applications:

| Bundle | Runtime | Dependencies | Emits |
|---|---|---|---|
| `azure-orders-api` | `azure-function-nodejs` | none | `azure-orders-api-service` (`name`, `url`) |
| `azure-orders-processor` | `azure-aks-helm-go` | `api` (orders API), `events` (queue), `receipts` (blob storage) | `azure-orders-processor-service` (`name`, `url`, `namespace`) |
| `azure-orders-worker` | `azure-function-nodejs` | `events` (queue), `lakehouse` (Databricks) | `azure-orders-worker-service` (`name`, `function_app_id`) |

Each application bundle is only a `massdriver.yaml`: a runtime reference, its
dependencies, a jq map from those dependencies to environment variables, and
its own resource type. `mass bundle build` and `mass bundle publish` pull the
runtime and merge the two. An application without its own `README.md` or
`operator.md` inherits the runtime's copy.

The application source lives in `apps/`:

| Directory | Contents |
|---|---|
| `apps/orders-api` | An HTTP-triggered Function. `GET /api/hello` returns a greeting. |
| `apps/orders-worker` | A queue-triggered Function that logs each order event it processes. |
| `apps/orders-processor` | A Go service and Dockerfile. `GET /` calls the orders API, and `POST /orders` writes an event to the queue and a receipt to blob storage. |

The processor ships with the public `gcr.io/google-samples/hello-app:2.0` image
as its default so the demo deploys without a container registry. Build and push
the real service with `make image IMAGE=<registry>/azure-orders-processor:<tag>`
and set the instance's `image` param to that reference.

## Resource types

| Type | Key fields |
|---|---|
| `azure-virtual-network` | `id`, `name`, `cidr`, `region`, `resource_group`, `subnets` |
| `azure-aks-cluster` | `id`, `name`, `region`, `resource_group`, and `authentication` (API server, CA, token) |
| `azure-blob-storage` | `id`, `name`, `container`, `endpoint`, `region`, `connection_string` |
| `azure-storage-queue` | `id`, `name`, `account_name`, `queue_url`, `poison_queue_name`, `region`, `connection_string` |
| `azure-databricks-workspace` | `id`, `name`, `region`, `workspace_url`, `workspace_id` |
| `azure-orders-api-service` | `name`, `url` |
| `azure-orders-processor-service` | `name`, `url`, `namespace` |
| `azure-orders-worker-service` | `name`, `function_app_id` |

Every application emits a resource type of its own rather than a shared generic
type, so a connection on the canvas says exactly which service it carries.
Connection strings are marked `$md.sensitive`.

## Design notes

The catalog favors a short path to a working demo over production hardening.

Storage accounts keep shared key access enabled, and consumers connect with the
connection string from the resource. The source Azure catalog disables shared
keys and uses managed identities with role assignments; port that back before
running these bundles in production.

The AKS API server is public because the Massdriver provisioner reaches it from
outside the network. The cluster uses the Free tier and one `Standard_B2ms`
node that autoscales to two.

The Databricks workspace keeps `no_public_ip = true`. Azure adds a NAT gateway
in the workspace's managed resource group for that, which is the largest fixed
cost in the application project.

Four bundles carry `src/alarms.tf` (Kubernetes, storage account, queue, and the
Function runtime), for 9 alarms bound to Azure Monitor metrics.

Massdriver runs Checkov on every deployment. Accepted findings are listed in
`src/.checkov.yml` with the reason next to each entry. The remaining open
findings, such as customer managed keys and zone redundancy, do not block a
deployment and are left visible on purpose.

Every infrastructure bundle and runtime has an `operator.md` with
`templating: mustache` front matter. The runbooks interpolate
`{{resources.<name>.<field>}}` and `{{params.<name>}}` into runnable commands,
and wrap resource-sourced sections in `{{#resources.<name>}}` guards so they
render before the first deployment.

## Publishing

Requirements: [Mass CLI](https://docs.massdriver.cloud/cli) 2.0.0 or later,
OpenTofu 1.8 or later, and an Azure service principal. Building the Function
packages needs Node.js 22, and building the processor image needs Docker.

```bash
export MASSDRIVER_ORG_ID=your-org
export MASSDRIVER_API_KEY=your-key
mass whoami
```

Publish in this order. An application build pulls its runtime from Massdriver,
so the runtimes must exist before the applications.

```bash
make publish-platforms       # the azure-service-principal credential type
make publish-resource-types  # the contracts
make publish-infra           # network, AKS, storage, queue, Databricks
make publish-runtimes        # azure-function-nodejs, azure-aks-helm-go
make publish-apps            # the three orders applications
```

Every bundle target publishes to the development release channel
(`--development`). Publishing updates every instance pinned to a matching
channel, such as `latest+dev`, and starts a deployment on it. Pin production
instances to an exact version to avoid that.

Then create an Azure Service Principal resource in the UI with the client ID,
tenant ID, client secret, and subscription ID, and set it as the default
credential in each environment.

## Deploying the example

1. Create the platform project with one environment. Add `azure-vnet` and
   `azure-kubernetes-service`, link the network to the cluster, and deploy both.
2. Grant the cluster resource to the application environment with
   `mass resource grant create <cluster-resource-id> --all-environments` (or a
   narrower `--condition`).
3. Create the application project. Add `azure-queue`, two
   `azure-storage-account` instances, and `azure-databricks`, then deploy them.
   Link the landing storage account to Databricks.
4. Deploy `azure-orders-api`. Build the Function packages with `make packages`,
   upload the zips to the instance's `packages` container, and set
   `package_url`.
5. Add `azure-orders-processor`, link the API, the queue, and the receipts
   storage to it, set its `kubernetes_cluster` remote reference to the cluster,
   and deploy.
6. Add `azure-orders-worker`, link the queue and Databricks to it, and deploy.

Check the result:

```bash
curl https://<api-function-app>.azurewebsites.net/api/hello
kubectl -n apps run curl --rm -i --restart=Never --image=curlimages/curl -- \
  curl -s http://<processor-service>.apps.svc.cluster.local/
```

Put a message on the `events` queue and the worker logs it in its
`FunctionAppLogs`.

Decommission the application environment before the platform environment, since
the processor runs on the cluster:

```bash
mass environment decommission <app-project>-<env>
mass environment decommission <platform-project>-<env>
```

## Azure permissions

| Scope | Role | Required by |
|---|---|---|
| Subscription | `Contributor` | Every bundle |
| Subscription | `User Access Administrator` | Role assignments made by the Function runtime and the Databricks bundle |

The credential instructions in the UI create a service principal with `Owner`
on the subscription, which covers both.

## Layout

```
bundles/
  <name>/
    massdriver.yaml    params, dependencies, resources, UI schema
    src/               OpenTofu: main.tf, resources.tf, alarms.tf, .checkov.yml
    chart/             Helm chart (azure-aks-helm-go only)
    README.md
    operator.md        runbook
    CHANGELOG.md
    icon.svg
apps/                  source for the three applications
resource-types/        the contracts between bundles
platforms/azure/       the service principal credential type
Makefile               build, validate, publish
```

Do not commit `_massdriver_variables.tf`, `schema-*.json`, `.terraform/`, state
files, `node_modules/`, `dist/`, or package zips. `.gitignore` covers them.
