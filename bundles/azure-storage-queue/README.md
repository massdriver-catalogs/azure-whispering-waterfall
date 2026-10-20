# Azure Storage Queue

This bundle creates a storage account, one queue, and a poison queue.

## Outputs

An `azure-storage-queue` resource. It carries the queue name, the queue URL,
the account name, the poison queue name, and the primary connection string.
Massdriver masks the connection string.

## Producers and consumers

Connect the queue to each application that sends or reads messages. The
application reads the connection string from the resource.

The Azure Functions queue trigger retries a message five times by default.
After the last retry, it moves the message to `<queue name>-poison`.

## Cost

A queue costs a fraction of a cent per 10,000 operations. A demo costs less
than one dollar per month.

## Immutable fields

The region and the queue name.
