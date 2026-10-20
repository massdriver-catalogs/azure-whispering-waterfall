# Import an AKS Cluster

Use these steps to register an AKS cluster that you created outside of
Massdriver.

## Create a deployer token

```bash
az aks get-credentials --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME>
kubectl -n kube-system create serviceaccount massdriver-deployer
kubectl create clusterrolebinding massdriver-deployer \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:massdriver-deployer
kubectl -n kube-system create token massdriver-deployer --duration=8760h
```

## Find the values

```bash
az aks show --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> \
  --query "{id:id, name:name, region:location, version:kubernetesVersion, node_resource_group:nodeResourceGroup}"
kubectl config view --raw --minify \
  -o jsonpath='{.clusters[0].cluster.server}{"\n"}{.clusters[0].cluster.certificate-authority-data}{"\n"}'
```

## Map the values

| Field | Source |
|---|---|
| `id`, `name`, `region`, `version`, `node_resource_group` | The `az aks show` output. |
| `resource_group` | The resource group of the cluster. |
| `authentication.cluster.server` | The first line of the `kubectl config view` output. |
| `authentication.cluster.certificate-authority-data` | The second line of the `kubectl config view` output. |
| `authentication.user.token` | The `kubectl create token` output. |
