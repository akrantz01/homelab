locals {
  secrets_path = "${get_repo_root()}/secrets/github/terraform.yaml"
  secrets      = yamldecode(sops_decrypt_file(local.secrets_path))
}

generate "cloudflare" {
  path      = "provider_cloudflare.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file("providers/cloudflare.tf")
}

inputs = {
  cloudflare_token = local.secrets.cloudflare.token
}
