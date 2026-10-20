# Databricks notebook source
# MAGIC %md
# MAGIC # Read the order events
# MAGIC The Orders Worker writes one JSON file per order event to the landing
# MAGIC container. This notebook reads all of them. Attach a cluster to run it.

# COMMAND ----------

scope = "landing"
account = dbutils.secrets.get(scope, "account-name")
container = dbutils.secrets.get(scope, "container")
connection_string = dbutils.secrets.get(scope, "connection-string")

# The account key is the AccountKey part of the connection string.
parts = dict(p.split("=", 1) for p in connection_string.split(";") if "=" in p)
spark.conf.set(f"fs.azure.account.key.{account}.dfs.core.windows.net", parts["AccountKey"])

# COMMAND ----------

events = spark.read.json(f"abfss://{container}@{account}.dfs.core.windows.net/orders/")
display(events.orderBy("processedAt", ascending=False))
