# Import an Azure Storage Queue

Use these steps to register a queue that you created outside of Massdriver.
The storage account must allow shared key access.

```bash
az storage account show --name <ACCOUNT_NAME> --query "{account_id:id, region:location}"
az storage account show-connection-string --name <ACCOUNT_NAME> --query connectionString -o tsv
```

| Field | Source |
|---|---|
| `id` | `<account_id>/queueServices/default/queues/<QUEUE_NAME>` |
| `name` | The name of the queue. |
| `account_name` | The name of the storage account. |
| `queue_url` | `https://<ACCOUNT_NAME>.queue.core.windows.net/<QUEUE_NAME>` |
| `connection_string` | The `show-connection-string` output. |
