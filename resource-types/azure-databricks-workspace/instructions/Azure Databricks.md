# Import an Azure Databricks Workspace

```bash
az databricks workspace show --resource-group <RESOURCE_GROUP> --name <WORKSPACE_NAME> \
  --query "{id:id, name:name, region:location, workspace_id:workspaceId, workspace_url:workspaceUrl, managed_resource_group:managedResourceGroupId}"
```

Add `https://` before the `workspace_url` value. Set `catalog` and `schema` to
the location of the demo tables.
