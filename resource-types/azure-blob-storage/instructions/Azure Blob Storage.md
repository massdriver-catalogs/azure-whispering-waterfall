# Import an Azure Blob Container

Use these steps to register a blob container that you created outside of
Massdriver. The storage account must allow shared key access.

```bash
az storage account show --name <ACCOUNT_NAME> \
  --query "{id:id, name:name, region:location, endpoint:primaryEndpoints.blob}"
az storage account show-connection-string --name <ACCOUNT_NAME> --query connectionString -o tsv
```

| Field | Source |
|---|---|
| `id`, `name`, `region` | The `az storage account show` output. |
| `container` | The name of the blob container. |
| `endpoint` | The blob endpoint plus the container name, for example `https://acct.blob.core.windows.net/landing`. |
| `connection_string` | The `show-connection-string` output. |
