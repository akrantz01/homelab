include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "aws" {
  path = find_in_parent_folders("providers/aws.hcl")
}

include "github" {
  path = find_in_parent_folders("providers/github.hcl")
}

dependency "bootstrap" {
  config_path = "../../bootstrap"

  mock_outputs = {
    github_oidc_provider_arn = "arn:aws:iam::000000000000:oidc-provider/token.actions.githubusercontent.com"
    state_bucket = {
      name        = "mock-state"
      arn         = "arn:aws:s3:::mock-state"
      region      = "ca-central-1"
      kms_key_arn = "arn:aws:kms:ca-central-1:000000000000:key/00000000-0000-0000-0000-000000000000"
    }
    project_state_policy_arn    = "arn:aws:iam::000000000000:policy/ProjectTerraformState"
    project_boundary_policy_arn = "arn:aws:iam::000000000000:policy/ProjectPermissionsBoundary"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  # The artifacts bucket lives in us-east-1, not the default region
  aws_region = "us-east-1"

  github_oidc_provider_arn = dependency.bootstrap.outputs.github_oidc_provider_arn
  state_bucket             = dependency.bootstrap.outputs.state_bucket
  state_policy_arn         = dependency.bootstrap.outputs.project_state_policy_arn
  boundary_policy_arn      = dependency.bootstrap.outputs.project_boundary_policy_arn
}
