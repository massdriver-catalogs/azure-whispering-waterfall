# An application bundle that extends this runtime adds its own dependencies
# and environment variables. This runtime does not know their names, so it
# reads the files that Massdriver renders before each deployment.
locals {
  envs_path    = "/massdriver/envs.json"
  secrets_path = "/massdriver/secrets.json"

  app_envs    = fileexists(local.envs_path) ? jsondecode(file(local.envs_path)) : {}
  app_secrets = fileexists(local.secrets_path) ? jsondecode(file(local.secrets_path)) : {}

  # Azure app settings are strings. A non-string value is JSON encoded.
  app_settings_from_app = {
    for k, v in merge(local.app_envs, local.app_secrets) :
    k => (can(tostring(v)) ? tostring(v) : jsonencode(v))
  }
}
