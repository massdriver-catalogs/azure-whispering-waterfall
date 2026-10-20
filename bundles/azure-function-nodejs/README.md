# Azure Function Runtime for Node.js

A runtime bundle for Node.js 22 (TypeScript) Azure Function apps on the Flex
Consumption plan. An application bundle sets
`app.runtime: azure-function-nodejs@<constraint>` and extends this runtime. Do
not deploy this runtime as a component.

## What the runtime creates

- A resource group, a Log Analytics workspace, and Application Insights.
- A host storage account with a `deployments` container.
- A Flex Consumption plan (`FC1`) and a Function app on Node.js 22.

## What an application bundle adds

| Item | How |
|---|---|
| Dependencies | `dependencies:` in the application `massdriver.yaml`. |
| Environment variables | `app.envs:` jq expressions. Each one becomes an app setting. |
| Secrets | `app.secrets:`. Each one becomes an app setting. |
| Connection strings | Automatic. A connected dependency with a `connection_string` field becomes the app setting `<DEPENDENCY NAME>_CONNECTION_STRING`. |
| Resources | `resources:` and a jq template on the `src` step. |

The `src` step has these outputs for resource templates: `function_app_name`,
`function_app_id`, `default_hostname`, `url`, and `resource_group`.

## Code deployment

Set **Package URL** to an HTTPS URL of the zip package. The bundle downloads the
package and deploys it. A new package (a different file) starts a new
deployment.

Leave the field empty to deploy the code yourself:

```bash
func azure functionapp publish <function app name>
```

## Cost

Flex Consumption has no fixed price. Azure charges for memory per second of
execution and per execution. The Log Analytics workspace charges per GiB of
logs.
