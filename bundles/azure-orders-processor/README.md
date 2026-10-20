# Orders Processor

A hello-world Go service on AKS. It runs on the `azure-aks-helm-go` runtime.

- `GET /` says hello and calls `GET /api/hello` on the Orders API.
- `POST /orders` sends an order event to the queue and writes a receipt blob.
- `GET /healthz` answers 200.

The source and the Dockerfile are in `apps/orders-processor`.

## Dependencies

| Name | Resource type | Use |
|---|---|---|
| `api` | `azure-orders-api-service` | `ORDERS_API_URL` |
| `events` | `azure-storage-queue` | `EVENTS_QUEUE_NAME`, `EVENTS_CONNECTION_STRING` |
| `receipts` | `azure-blob-storage` | `RECEIPTS_CONTAINER`, `RECEIPTS_CONNECTION_STRING` |
