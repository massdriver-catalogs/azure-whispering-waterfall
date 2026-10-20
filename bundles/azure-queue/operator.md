---
templating: mustache
---

# Storage Queue Runbook

## Count the messages

{{#resources.queue}}
```bash
CS="$(az storage account show-connection-string --name {{resources.queue.account_name}} -o tsv)"
az storage message peek --connection-string "$CS" --queue-name {{resources.queue.name}} --num-messages 32 -o table
az storage queue metadata show --connection-string "$CS" --name {{resources.queue.name}}
```
{{/resources.queue}}

## Messages go to the poison queue

The consumer failed to process the message five times.

{{#resources.queue}}
1. Read the failed messages.
   ```bash
   CS="$(az storage account show-connection-string --name {{resources.queue.account_name}} -o tsv)"
   az storage message peek --connection-string "$CS" --queue-name {{resources.queue.poison_queue_name}} --num-messages 32
   ```
2. Read the logs of the consumer to find the error.
3. Fix the consumer. Then send the messages to {{resources.queue.name}} again.
{{/resources.queue}}

## Rotate the key

{{#resources.queue}}
1. Renew the primary key.
   ```bash
   az storage account keys renew --account-name {{resources.queue.account_name}} --key primary
   ```
2. Deploy this bundle again. The resource then carries the new connection string.
3. Deploy every producer and consumer again.
{{/resources.queue}}
