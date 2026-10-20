---
templating: mustache
---

# Storage Account Runbook

## Health check

{{#resources.bucket}}
```bash
az storage account show \
  --ids {{resources.bucket.id}} \
  --query "{state:provisioningState, tls:minimumTlsVersion, sharedKey:allowSharedKeyAccess}"
```
{{/resources.bucket}}

## An application gets `AuthenticationFailed`

The connection string of the application holds an old key.

{{#resources.bucket}}
1. Read the current connection string.
   ```bash
   az storage account show-connection-string --ids {{resources.bucket.id}} --query connectionString -o tsv
   ```
2. Deploy the consumer again, so that it reads the current resource.
{{/resources.bucket}}

## Rotate the key

{{#resources.bucket}}
1. Renew the primary key.
   ```bash
   az storage account keys renew --account-name {{resources.bucket.name}} --key primary
   ```
2. Deploy this bundle again. The resource then carries the new connection string.
3. Deploy every consumer again.
{{/resources.bucket}}

## A deployment fails with `StorageAccountAlreadyTaken`

The account name is global to Azure, and another tenant holds it. The random
suffix makes this rare. Decommission the instance, then deploy it again to get a
new suffix.

## List the blobs

{{#resources.bucket}}
```bash
az storage blob list \
  --connection-string "$(az storage account show-connection-string --ids {{resources.bucket.id}} -o tsv)" \
  --container-name {{resources.bucket.container}} --output table
```
{{/resources.bucket}}
