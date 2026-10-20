---
templating: mustache
---

# Databricks Workspace Runbook

## Open the workspace

{{#resources.workspace}}
Go to {{resources.workspace.workspace_url}}. Sign in with an Entra ID account
that has the Contributor role on the workspace.
{{/resources.workspace}}

## The notebook fails with `Secret does not exist`

The `landing` dependency was not connected at deploy time, so the bundle
created no secret scope.

1. Connect an `azure-blob-storage` resource to `landing`.
2. Deploy this bundle again.

## The notebook finds no files

The Orders Worker has not processed an event yet, or it writes to a different
container. Confirm that the worker and this workspace connect to the same
landing blob storage.
