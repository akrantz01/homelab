resource "github_actions_secret" "aws_assume_role" {
  repository      = "homelab"
  secret_name     = "AWS_ASSUME_ROLE_ARN"
  plaintext_value = aws_iam_role.homelab.arn
}

resource "github_actions_secret" "tailfed_aws_assume_role" {
  repository      = "tailfed"
  secret_name     = "AWS_ASSUME_ROLE_ARN"
  plaintext_value = aws_iam_role.tailfed.arn
}

