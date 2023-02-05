resource "random_string" "github_secret" {
  length = 64

  lower   = true
  upper   = true
  numeric = true
  special = true

  min_lower   = 4
  min_upper   = 4
  min_numeric = 4
  min_special = 4
}

resource "aws_ssm_parameter" "github_secret" {
  name  = "/salt/github-webhook"
  type  = "SecureString"
  value = random_string.github_secret.result

  overwrite = true
  tier      = "Standard"
}
