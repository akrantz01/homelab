include "root" {
  path   = find_in_parent_folders()
  expose = true
}

locals {
  secrets = include.root.locals.secrets
}

inputs = {
  cloudflare_token = local.secrets.cloudflare.token
  regions          = local.secrets.regions
}
