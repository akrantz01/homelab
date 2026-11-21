locals {
  secrets = yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/github/terraform.yaml"))
}

generate "provider_b2" {
  path      = "provider_b2.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file("${get_repo_root()}/terraform/providers/b2.tf")
}

inputs = {
  b2_application_key    = local.secrets.b2.application_key
  b2_application_key_id = local.secrets.b2.key_id
}
