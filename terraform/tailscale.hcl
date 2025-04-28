locals {
  secrets_path = "${get_repo_root()}/secrets/github/terraform.yaml"
  secrets      = yamldecode(sops_decrypt_file(local.secrets_path))
}

generate "tailscale" {
  path      = "provider_tailscale.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file("providers/tailscale.tf")
}

inputs = {
  tailscale_tailnet             = local.secrets.tailscale.tailnet
  tailscale_oauth_client_id     = local.secrets.tailscale.oauth.client_id
  tailscale_oauth_client_secret = local.secrets.tailscale.oauth.client_secret
}
