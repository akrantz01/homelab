include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "provider_aws" {
  path = find_in_parent_folders("providers/aws.hcl")
}

include "provider_tailscale" {
  path = find_in_parent_folders("providers/tailscale.hcl")
}

exclude {
  if      = true
  actions = ["all_except_output"]
}

inputs = {
  state_bucket     = include.root.locals.secrets.state.bucket
  state_lock_table = include.root.locals.secrets.state.lock_table
}
