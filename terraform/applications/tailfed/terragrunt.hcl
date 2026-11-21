include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "aws" {
  path = find_in_parent_folders("aws.hcl")
}

include "cloudflare" {
  path = find_in_parent_folders("cloudflare.hcl")
}

include "tailscale" {
  path = find_in_parent_folders("tailscale.hcl")
}

dependency "github-actions" {
  config_path = "../../github-actions"

  skip_outputs = true
}

inputs = {
  tailscale_oauth_scopes = ["auth_keys"]
}
