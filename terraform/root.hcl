locals {
  secrets_path = "${get_repo_root()}/secrets/github/terraform.yaml"
  secrets      = yamldecode(sops_decrypt_file(local.secrets_path))
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    region  = local.secrets.regions.aws
    encrypt = true

    bucket = local.secrets.state.bucket
    key    = "${path_relative_to_include()}/terraform.tfstate"

    dynamodb_table = local.secrets.state.lock_table
  }
}

terraform {
  extra_arguments "disable_input" {
    commands  = get_terraform_commands_that_need_input()
    arguments = ["-input=false"]
  }
}

terraform_binary = "tofu"
