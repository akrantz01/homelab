locals {
  secrets_path = "${get_repo_root()}/secrets/github/terraform.yaml"
  secrets      = yamldecode(sops_decrypt_file(local.secrets_path))
}

generate "github" {
  path      = "provider_github.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file("providers/github.tf")
}

inputs = {
  github_owner = local.secrets.github.owner
  github_app   = local.secrets.github.app
}
