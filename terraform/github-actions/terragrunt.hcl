include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "aws" {
  path = find_in_parent_folders("aws.hcl")
}

inputs = {
  state_bucket     = include.root.locals.secrets.state.bucket
  state_lock_table = include.root.locals.secrets.state.lock_table
}
