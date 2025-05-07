locals {
  secrets_path = "${get_repo_root()}/secrets/github/idp.yaml"
  secrets      = yamldecode(sops_decrypt_file(local.secrets_path))
}

include "root" {
  path = find_in_parent_folders()
}

include "aws" {
  path = find_in_parent_folders("aws.hcl")
}

dependency "github-actions" {
  config_path = "../../github-actions"

  skip_outputs = true
}

inputs = {
  subnet_id = "subnet-d1268cab"

  flake    = "github:akrantz01/homelab#idp"
  host_key = local.secrets.host_key
}
