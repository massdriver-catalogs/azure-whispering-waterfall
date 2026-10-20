# Orders API

A hello-world TypeScript Azure Function app. It runs on the
`azure-function-nodejs` runtime.

- `GET /api/hello` returns a JSON greeting.

The source is in `apps/orders-api`. Build the zip package with
`npm ci && npm run package`, upload it to a URL that Azure can read, and set
the **Package URL** field.

## Outputs

An `azure-orders-api-service` resource with the name and the URL of the app.
Connect it to the Orders Processor.
