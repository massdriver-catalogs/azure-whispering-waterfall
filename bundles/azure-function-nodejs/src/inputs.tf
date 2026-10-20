# An application bundle that extends this runtime adds its own dependencies and
# environment variables. This runtime does not know their names, so it reads
# the files that Massdriver writes before each deployment.
locals {
  envs_path         = "/massdriver/envs.json"
  secrets_path      = "/massdriver/secrets.json"
  dependencies_path = "/massdriver/dependencies.json"

  app_envs     = fileexists(local.envs_path) ? jsondecode(file(local.envs_path)) : {}
  app_secrets  = fileexists(local.secrets_path) ? jsondecode(file(local.secrets_path)) : {}
  dependencies = fileexists(local.dependencies_path) ? jsondecode(file(local.dependencies_path)) : {}

  # Each connected dependency that carries a `connection_string` becomes the
  # app setting <DEPENDENCY NAME>_CONNECTION_STRING. Example: the dependency
  # `events` becomes EVENTS_CONNECTION_STRING.
  connection_strings = {
    for name, dep in local.dependencies :
    "${upper(name)}_CONNECTION_STRING" => dep.connection_string
    if can(dep.connection_string)
  }
}
