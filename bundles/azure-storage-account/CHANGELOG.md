# Changelog

## 0.1.0

- Copy the bundle from the base Azure catalog (massdriver-catalogs/azure).
- Emit the `azure-blob-storage` resource type with a sensitive connection string.
- Turn on shared key access, so that applications can use the connection string.
- Add a region field. Remove the network, log workspace, key vault, and private DNS zone dependencies.
- Add a random suffix to the account name, because the name is global to Azure.
