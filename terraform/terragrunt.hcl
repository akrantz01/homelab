locals {
  aws_region = get_env("AWS_REGION", "ca-central-1")
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    region  = local.aws_region
    encrypt = true

    bucket = get_env("TF_STATE_BUCKET")
    key    = "${path_relative_to_include()}/terraform.tfstate"

    dynamodb_table = get_env("TF_STATE_LOCK_TABLE")
  }
}

terraform_binary             = "tofu"
terraform_version_constraint = "~> 1.6.0"
