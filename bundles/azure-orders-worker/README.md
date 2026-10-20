# Orders Worker

A TypeScript Azure Function app with a queue trigger. It runs on the
`azure-function-nodejs` runtime. It reads each order event from the connected
queue and writes it to the log.

The source is in `apps/orders-worker`. The app envs map the dependencies to app
settings:

| App setting | Source |
|---|---|
| `EVENTS_QUEUE_NAME` | `events.name` |
| `EVENTS_CONNECTION_STRING` | `events.connection_string` (sensitive) |
| `DATABRICKS_HOST` | `lakehouse.workspace_url` |
| `DATABRICKS_WORKSPACE` | `lakehouse.name` |

The queue trigger reads the connection string from `EVENTS_CONNECTION_STRING`.
The worker does not call Databricks. It writes the Databricks values to the log
for each event.

## Deploy the code

Upload the zip from `npm run package` to the `packages` container of this app,
then set **Package URL** to the blob name. See the runtime README.

## Outputs

An `azure-orders-worker-service` resource with the name and the resource ID of
the app.
