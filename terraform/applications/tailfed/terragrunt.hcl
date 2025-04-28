locals {
  secrets_path = "${get_repo_root()}/secrets/github/tailfed.yaml"
  secrets      = yamldecode(sops_decrypt_file(local.secrets_path))
}

include "root" {
  path = find_in_parent_folders()
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

  tailfed_tailscale_oauth_client_id     = local.secrets.tailscale.oauth.client_id
  tailfed_tailscale_oauth_client_secret = local.secrets.tailscale.oauth.client_secret
}
