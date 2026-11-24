locals {
  secrets = yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/github/terraform.yaml"))
}

generate "provider_aws" {
  path      = "provider_aws.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file("${get_repo_root()}/terraform/providers/aws.tf")
}

inputs = {
  aws_region = local.secrets.regions.aws
  aws_default_tags = {
    ManagedBy  = "Terraform"
    Repository = "alex/homelab"
    Unit       = trimprefix(get_terragrunt_dir(), "${get_repo_root()}/terraform/")
  }
}
