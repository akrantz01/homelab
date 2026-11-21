locals {
  secrets = yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/github/terraform.yaml"))
}

generate "provider_cloudflare" {
  path      = "provider_cloudflare.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file("${get_repo_root()}/terraform/providers/cloudflare.tf")
}

inputs = {
  cloudflare_token = local.secrets.cloudflare.token
}
