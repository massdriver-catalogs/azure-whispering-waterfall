# Changelog

## 0.1.0

- Add the first version of the runtime.
- Create a Node.js 22 Function app on the Flex Consumption plan.
- Map app envs and app secrets to app settings.
- Deploy the code from a blob in the `packages` container or from an HTTPS URL. Azure Storage copies the package to `deployments/released-package.zip` on the server side.
- Emit the `packages` resource, and write the function logs to the host storage account.
- Make Application Insights optional.
