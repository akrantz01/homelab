include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider_tailscale" {
  path = find_in_parent_folders("providers/tailscale.hcl")
}

exclude {
  if      = true
  actions = ["all_except_output"]
}
