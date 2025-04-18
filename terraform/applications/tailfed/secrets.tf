resource "tailscale_tailnet_key" "verifier" {
  description = "Tailnet key for verifier Lambda"

  reusable      = true
  ephemeral     = true
  preauthorized = true
  expiry        = 30 * 60 * 60 * 24 # 30 days

  tags = ["tag:homelab"]

  recreate_if_invalid = "always"
}

resource "aws_ssm_parameter" "tailnet" {
  name  = "/tailfed/tailscale/tailnet"
  type  = "String"
  value = var.tailscale_tailnet

  key_id    = aws_kms_alias.secrets.arn
  overwrite = true
}

resource "aws_ssm_parameter" "auth_key" {
  name  = "/tailfed/tailscale/auth-key"
  type  = "SecureString"
  value = tailscale_tailnet_key.verifier.key

  key_id    = aws_kms_alias.secrets.arn
  overwrite = true
}

resource "aws_ssm_parameter" "oauth_client_id" {
  name  = "/tailfed/tailscale/oauth/client-id"
  type  = "SecureString"
  value = var.tailfed_tailscale_oauth_client_id

  key_id    = aws_kms_alias.secrets.arn
  overwrite = true
}

resource "aws_ssm_parameter" "oauth_client_secret" {
  name  = "/tailfed/tailscale/oauth/client-secret"
  type  = "SecureString"
  value = var.tailfed_tailscale_oauth_client_secret

  key_id    = aws_kms_alias.secrets.arn
  overwrite = true
}

data "aws_iam_policy_document" "secrets_access" {
  statement {
    sid     = "AllowGetParameter"
    effect  = "Allow"
    actions = ["ssm:GetParameter"]
    resources = [
      aws_ssm_parameter.tailnet.arn,
      aws_ssm_parameter.auth_key.arn,
      aws_ssm_parameter.oauth_client_id.arn,
      aws_ssm_parameter.oauth_client_secret.arn
    ]
  }

  statement {
    sid     = "AllowDecryptParameter"
    effect  = "Allow"
    actions = ["kms:Decrypt"]
    resources = [
      aws_kms_key.secrets.arn,
      aws_kms_alias.secrets.arn
    ]
  }
}

resource "aws_kms_key" "secrets" {
  description = "KMS key for encrypting Tailfed secrets"
  key_usage   = "ENCRYPT_DECRYPT"
  policy      = data.aws_iam_policy_document.secrets.json
}

resource "aws_kms_alias" "secrets" {
  target_key_id = aws_kms_key.secrets.key_id
  name          = "alias/tailfed/secrets"
}

data "aws_iam_policy_document" "secrets" {
  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}
