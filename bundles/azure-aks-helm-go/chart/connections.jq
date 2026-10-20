# Keep only the dependencies that carry a connection string. The cluster
# credential stays out of the chart values.
{
  dependencies: with_entries(select((.value | type) == "object" and (.value | has("connection_string"))))
}
