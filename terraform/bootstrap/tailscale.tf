locals {
  tailscale_scopes           = ["federated_keys"]
  tailscale_read_only_scopes = [for scope in local.tailscale_scopes : "${scope}:read"]
}

resource "tailscale_federated_identity" "plan" {
  description = "GitHub Actions - akrantz01 homelab - plan"
  scopes      = local.tailscale_read_only_scopes

  issuer  = "https://token.actions.githubusercontent.com"
  subject = "repo:${data.github_repository.source.full_name}:ref:refs/heads/*"
}

resource "tailscale_federated_identity" "apply" {
  description = "GitHub Actions - akrantz01 homelab - apply"
  scopes      = local.tailscale_scopes

  issuer  = "https://token.actions.githubusercontent.com"
  subject = "repo:${data.github_repository.source.full_name}:environment:${github_repository_environment.production.environment}"
}
