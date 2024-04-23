locals {
  secrets_path = "${get_repo_root()}/secrets/terraform.yaml"
  secrets      = yamldecode(sops_decrypt_file(local.secrets_path))
}

generate "aws" {
  path      = "provider_aws.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file("providers/aws.tf")
}

inputs = {
  aws_region = local.secrets.regions.aws
}
