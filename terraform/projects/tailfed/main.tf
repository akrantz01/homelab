terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.73.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
  }
}

module "project" {
  source = "../../modules/project"

  providers = {
    aws    = aws
    github = github
  }

  repository = "tailfed"
  refs       = ["refs/heads/main", "refs/tags/*"]

  policies = {
    Artifacts = data.aws_iam_policy_document.project_artifacts.json
  }

  github_oidc_provider_arn = var.github_oidc_provider_arn
  state_bucket             = var.state_bucket
  state_policy_arn         = var.state_policy_arn
  boundary_policy_arn      = var.boundary_policy_arn
}

data "aws_iam_policy_document" "project_artifacts" {
  statement {
    sid       = "ManageArtifactBuckets"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::tailfed-artifacts"]
  }
}
