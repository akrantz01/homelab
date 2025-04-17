resource "tailscale_tailnet_key" "verifier" {
  description = "Tailnet key for verifier Lambda"

  reusable      = true
  ephemeral     = true
  preauthorized = true
  expiry        = 60 * 60 * 24 # 1 day
  # expiry        = 30 * 60 * 60 * 24 # 30 days

  tags = ["tag:homelab"]

  recreate_if_invalid = "always"
}

resource "aws_ssm_parameter" "tailnet" {
  name  = "/tailfed/tailscale/tailnet"
  type  = "String"
  value = var.tailscale_tailnet

  overwrite = true
}

resource "aws_ssm_parameter" "auth_key" {
  name  = "/tailfed/tailscale/auth-key"
  type  = "SecureString"
  value = tailscale_tailnet_key.verifier.key

  overwrite = true
}

resource "aws_ssm_parameter" "oauth_client_id" {
  name  = "/tailfed/tailscale/oauth/client-id"
  type  = "SecureString"
  value = var.tailfed_tailscale_oauth_client_id

  overwrite = true
}

resource "aws_ssm_parameter" "oauth_client_secret" {
  name  = "/tailfed/tailscale/oauth/client-secret"
  type  = "SecureString"
  value = var.tailfed_tailscale_oauth_client_secret

  overwrite = true
}
