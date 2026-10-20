# Azure Storage Account

This bundle creates a storage account and one blob container.

## Outputs

An `azure-blob-storage` resource. It carries the account name, the container
name, the container URL, and the primary connection string. Massdriver masks
the connection string.

## Access

An application connects with the connection string. The connection string
gives full access to the account, so connect the bucket only to the
applications that need it.

The account accepts traffic from the public endpoint, because the applications
of this catalog run outside a virtual network. Every request needs the key. No
container is public. The minimum TLS version is 1.2.

## Account name

Azure permits 3 to 24 lowercase letters and digits, and the name is global to
Azure. The bundle uses the first 18 characters of the instance name without
hyphens, and adds 6 random characters.

## Cost

Local redundancy and the Hot tier cost the least for a demo. Storage costs
about 2 cents per GiB per month in `eastus2`.

## Immutable fields

The region and the container name.
