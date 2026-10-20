# Azure Kubernetes Service

This bundle creates a cluster in the connected network. A Helm bundle deploys
onto it with the deployer token that this bundle creates.

## Network

The cluster uses the first subnet without a delegation. The Azure network plugin
gives every pod an address from that subnet, so the subnet needs free space.

Each node takes about 30 addresses. A `/24` subnet holds about 8 nodes.

## Outputs

An `azure-aks-cluster` resource. It carries the API server address, the
certificate authority, and the token of the `massdriver-deployer` service
account. The Massdriver Helm provisioner reads these fields. Massdriver masks
the token, and it records every download of the kubeconfig.

## Deployer token

The bundle creates the `massdriver-deployer` service account in `kube-system`
with the `cluster-admin` role, and a token secret that does not expire. To
rotate the token, delete the `massdriver-deployer-token` secret and deploy the
bundle again.

The API server must accept traffic from the Massdriver provisioner. Do not turn
on the private API server when a Helm bundle deploys onto this cluster.

## Cost

| Item | Cost |
|---|---|
| Free tier control plane | No charge, and no uptime promise. |
| Standard tier control plane | About 73 dollars per month. |
| Nodes | The price of each virtual machine, per hour. |

## Immutable fields

The private API server. Azure sets it at creation.
