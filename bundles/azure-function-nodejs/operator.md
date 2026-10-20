---
templating: mustache
---

# Function App Runbook

## Read the logs

```bash
az monitor app-insights query \
  --app {{params.md_metadata.name_prefix}} \
  --resource-group {{params.md_metadata.name_prefix}} \
  --analytics-query "traces | order by timestamp desc | take 50"
```

## The app answers HTTP 404 on every route

The Function app holds no code. Set **Package URL** and deploy again, or
publish the code from the app source directory.

```bash
npm ci && npm run build
func azure functionapp publish {{params.md_metadata.name_prefix}}
```

## The deployment fails with "The package URL did not return HTTP 200"

Azure cannot read the package URL. Open the URL in a private browser window.
A private GitHub release or a blob without a SAS token returns 404 or 403.

## Read the app settings

```bash
az functionapp config appsettings list \
  --name {{params.md_metadata.name_prefix}} \
  --resource-group {{params.md_metadata.name_prefix}} -o table
```
