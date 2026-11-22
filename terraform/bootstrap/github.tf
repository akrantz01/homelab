locals {
  terraform_apply_subject = "repo:${data.github_repository.source.full_name}:environment:${github_repository_environment.production.environment}"
  terraform_plan_subject  = "repo:${data.github_repository.source.full_name}:ref:refs/heads/*"
}

data "github_repository" "source" {
  name = "homelab"
}

resource "github_repository_environment" "production" {
  repository  = data.github_repository.source.name
  environment = "production"

  can_admins_bypass = false

  deployment_branch_policy {
    protected_branches     = true
    custom_branch_policies = false
  }
}

resource "github_actions_variable" "tailscale_client_id" {
  repository = data.github_repository.source.name

  variable_name = "TAILSCALE_OAUTH_CLIENT_ID"
  value         = tailscale_federated_identity.plan.id
}

resource "github_actions_variable" "tailscale_audience" {
  repository = data.github_repository.source.name

  variable_name = "TAILSCALE_AUDIENCE"
  value         = tailscale_federated_identity.plan.audience
}

resource "github_actions_variable" "aws_role" {
  repository = data.github_repository.source.name

  variable_name = "AWS_ROLE_ARN"
  value         = aws_iam_role.plan.arn
}

resource "github_actions_environment_variable" "tailscale_client_id" {
  repository = data.github_repository.source.name

  environment   = github_repository_environment.production.environment
  variable_name = "TAILSCALE_OAUTH_CLIENT_ID"
  value         = tailscale_federated_identity.apply.id
}

resource "github_actions_environment_variable" "tailscale_audience" {
  repository = data.github_repository.source.name

  environment   = github_repository_environment.production.environment
  variable_name = "TAILSCALE_AUDIENCE"
  value         = tailscale_federated_identity.apply.audience
}

resource "github_actions_environment_variable" "aws_role" {
  repository = data.github_repository.source.name

  environment   = github_repository_environment.production.environment
  variable_name = "AWS_ROLE_ARN"
  value         = aws_iam_role.apply.arn
}
