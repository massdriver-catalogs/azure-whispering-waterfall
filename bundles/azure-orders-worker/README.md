# Orders Worker

A TypeScript Azure Function app with a queue trigger. It runs on the
`azure-function-nodejs` runtime. It reads each order event from the connected
queue and writes it to the log.

The source is in `apps/orders-worker`. The trigger reads the connection string
from the app setting `EVENTS_CONNECTION_STRING`. The runtime creates that
setting from the `events` dependency.

## Outputs

An `azure-orders-worker-service` resource with the name and the resource ID of
the app.
