# Azure Function Runtime for Node.js

A runtime bundle for Node.js 22 (TypeScript) Azure Function apps on the Flex
Consumption plan. An application bundle sets
`app.runtime: azure-function-nodejs@<constraint>` and extends this runtime. Do
not deploy this runtime as a component.

## What the runtime creates

- A resource group.
- A host storage account with a `deployments` container and a `packages` container.
- A Flex Consumption plan (`FC1`) and a Function app on Node.js 22. The app has no VNet integration.
- Optional: a Log Analytics workspace and Application Insights.
- A diagnostic setting that writes the function logs to the host storage account.
- The `packages` resource (`azure-blob-storage`): the packages container, with a blob-only SAS connection string that expires 30 days after the last deployment.

## What an application bundle adds

| Item | How |
|---|---|
| Dependencies | `dependencies:` in the application `massdriver.yaml`. |
| Environment variables | `app.envs:` jq expressions. Each one becomes an app setting. Map a dependency field, such as a connection string, to an env. |
| Secrets | `app.secrets:`. Each one becomes an app setting. |
| Resources | `resources:` and a jq template on the `src` step. |

The `src` step has these outputs for resource templates: `function_app_name`,
`function_app_id`, `default_hostname`, `url`, and `resource_group`.

## Code deployment

1. Deploy the app one time with an empty **Package URL**. This creates the `packages` container.
2. Build the zip with `npm run package` in the app source directory.
3. Upload the zip to the `packages` container with the connection string of the `packages` resource.
4. Set **Package URL** to the blob name, for example `orders-api-0.1.0.zip`, and deploy again.

**Package URL** also accepts an HTTPS URL that Azure can read. Azure Storage
copies the package to `deployments/released-package.zip` on the server side,
with a read-only SAS that expires after two hours. The Flex Consumption host
runs that package. A new value of **Package URL** replaces the blob and
restarts the app. Use a new blob name for each release.

A copied package does not register its triggers with the Flex scale
controller. On each deployment with a package, the runtime calls the ARM action
`syncfunctiontriggers` with the `azapi` provider. Without this call, a queue
trigger does not start an instance when a message arrives.

## Cost

Flex Consumption has no fixed price. Azure charges for memory per second of
execution and per execution. The host storage account and the Log Analytics
workspace charge per GB.
