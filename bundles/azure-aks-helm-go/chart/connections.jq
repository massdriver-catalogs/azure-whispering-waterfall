# Keep only the dependencies that carry a connection string. The cluster
# credential stays out of the chart values. The input is the dependencies
# document, or the full jq context that holds it under .dependencies.
(if has("dependencies") and has("params") then .dependencies else . end)
| { dependencies: with_entries(select((.value | type) == "object" and (.value | has("connection_string")))) }
