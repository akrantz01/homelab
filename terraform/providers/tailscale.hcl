locals {
  secrets = yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/github/terraform.yaml"))
}

generate "provider_tailscale" {
  path      = "provider_tailscale.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file("${get_repo_root()}/terraform/providers/tailscale.tf")
}

inputs = {
  tailscale_tailnet             = local.secrets.tailscale.tailnet
  tailscale_oauth_client_id     = local.secrets.tailscale.oauth.client_id
  tailscale_oauth_client_secret = local.secrets.tailscale.oauth.client_secret
}
