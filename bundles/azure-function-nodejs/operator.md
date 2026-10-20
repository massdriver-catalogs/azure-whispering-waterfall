---
templating: mustache
---

# Function App Runbook

{{#resources.packages}}
## Upload a new package

Build the zip in the app source directory, then upload it with the SAS of the
`packages` resource. Copy the `SharedAccessSignature` value of the connection
string into `SAS`.

```bash
npm ci && npm run package
SAS='<SharedAccessSignature value>'
curl -sf -X PUT -H "x-ms-blob-type: BlockBlob" \
  --data-binary @<app>.zip \
  "{{resources.packages.endpoint}}/<app>-<version>.zip?$SAS"
```

Set **Package URL** to `<app>-<version>.zip` and deploy.

## Read the function logs

The diagnostic setting writes the logs to the host storage account. The first
logs arrive 5 to 10 minutes after an invocation.

```bash
curl -s "https://{{resources.packages.name}}.blob.core.windows.net/insights-logs-functionapplogs?restype=container&comp=list&$SAS" \
  | grep -o '<Name>[^<]*</Name>' | tail -5
```
{{/resources.packages}}

## The app answers HTTP 404 on every route

The Function app holds no code, or the package has no functions. Check that
**Package URL** is set. Check that the zip holds `host.json`, `package.json`,
`dist/`, and `node_modules/@azure/functions` at the root.

## The deployment fails with "The package URL did not return HTTP 200"

The blob does not exist in the `packages` container, or the URL needs a
sign-in. List the blobs:

```bash
curl -s "<packages endpoint>?restype=container&comp=list&$SAS" | grep -o '<Name>[^<]*</Name>'
```

## The SAS of the packages resource expired

The SAS expires 30 days after the last deployment. Deploy the app again with
the same params to get a new SAS.
