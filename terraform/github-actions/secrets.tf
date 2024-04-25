resource "github_actions_secret" "aws_assume_role" {
  repository      = "homelab"
  secret_name     = "AWS_ASSUME_ROLE_ARN"
  plaintext_value = aws_iam_role.homelab.arn
}
