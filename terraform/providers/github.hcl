locals {
  secrets = yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/github/terraform.yaml"))
}

generate "provider_github" {
  path      = "provider_github.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file("${get_repo_root()}/terraform/providers/github.tf")
}

inputs = {
  github_owner = local.secrets.github.owner
  github_app   = local.secrets.github.app
}
