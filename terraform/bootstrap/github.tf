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
