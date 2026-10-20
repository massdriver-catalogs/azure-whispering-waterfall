# Changelog

## 0.1.0

- Copy the bundle from the base Azure catalog (massdriver-catalogs/azure).
- Emit the `azure-aks-cluster` resource type.
- Create the `massdriver-deployer` service account and its token for the Massdriver Helm provisioner.
- Remove the optional key vault and the disk encryption set.
- Use the default Kubernetes version of Azure when the version field is empty.
- Set the lowest cost defaults: `Standard_B2ms` nodes, 1 to 2 nodes, Free tier.
- Declare the node pool upgrade settings, so that a deployment with no change shows no plan change.
