# Azure Databricks Workspace

This bundle creates an Azure Databricks workspace for a demo. It starts no
compute, so it has no cost until somebody starts a cluster or a SQL warehouse.

## Landing container

Connect an `azure-blob-storage` resource as `landing`. The bundle then creates
these items in the workspace:

- The secret scope `landing` with the keys `connection-string`,
  `account-name`, and `container`.
- The notebook `/Shared/orders/read_landing`, which reads the JSON files under
  `orders/` in the container.

## Outputs

An `azure-databricks-workspace` resource with the workspace URL and IDs.

## Cost

The Premium workspace has no fixed price. A cluster or a SQL warehouse costs
money while it runs. Use a single-node cluster with auto termination for the
demo.

## Immutable fields

The region.
