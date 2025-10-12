locals {
  secrets_path = "${get_repo_root()}/secrets/github/idp.yaml"
  secrets      = yamldecode(sops_decrypt_file(local.secrets_path))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "aws" {
  path = find_in_parent_folders("aws.hcl")
}

include "cloudflare" {
  path = find_in_parent_folders("cloudflare.hcl")
}

dependency "github-actions" {
  config_path = "../../github-actions"

  skip_outputs = true
}

dependency "networking" {
  config_path = "../../networking"
}

inputs = {}
