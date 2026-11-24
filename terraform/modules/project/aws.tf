locals {
  prefix = coalesce(var.prefix, var.repository)
}

resource "aws_iam_role" "project" {
  name        = "Project${replace(title(replace(var.repository, "/[_-]/", " ")), " ", "")}"
  path        = "/projects/"
  description = "Deploys resources from the ${data.github_repository.project.full_name} repository on GitHub"

  assume_role_policy   = data.aws_iam_policy_document.trust.json
  permissions_boundary = var.boundary_policy_arn

  tags = {
    Project       = var.repository
    ProjectPrefix = local.prefix
  }
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = concat(
        [for ref in var.refs : "repo:${data.github_repository.project.full_name}:ref:${ref}"],
        [for environment in var.environments : "repo:${data.github_repository.project.full_name}:environment:${environment}"],
      )
    }
  }
}

resource "aws_iam_role_policy" "project" {
  for_each = var.policies

  name   = each.key
  role   = aws_iam_role.project.id
  policy = each.value
}

resource "aws_iam_role_policies_exclusive" "project" {
  role_name    = aws_iam_role.project.name
  policy_names = [for policy in aws_iam_role_policy.project : policy.name]
}

resource "aws_iam_role_policy_attachments_exclusive" "project" {
  role_name   = aws_iam_role.project.name
  policy_arns = concat([var.state_policy_arn], var.policy_arns)
}
