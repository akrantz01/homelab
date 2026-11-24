resource "github_actions_variable" "aws_role" {
  repository    = data.github_repository.project.name
  variable_name = "AWS_ROLE_ARN"
  value         = aws_iam_role.project.arn
}

resource "github_actions_variable" "state_bucket" {
  repository    = data.github_repository.project.name
  variable_name = "TERRAFORM_STATE_BUCKET"
  value         = var.state_bucket.name
}

resource "github_actions_variable" "state_key" {
  repository    = data.github_repository.project.name
  variable_name = "TERRAFORM_STATE_KEY"
  value         = local.state_key
}

resource "github_actions_variable" "state_region" {
  repository    = data.github_repository.project.name
  variable_name = "TERRAFORM_STATE_REGION"
  value         = var.state_bucket.region
}
