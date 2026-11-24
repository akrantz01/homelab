resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "plan" {
  name        = "HomelabTerraformPlan"
  description = "The role assumed by the Terraform Plan job in the akrantz01/homelab repository on GitHub"

  assume_role_policy = data.aws_iam_policy_document.plan_trust_policy.json
}

resource "aws_iam_role_policy_attachments_exclusive" "plan" {
  role_name = aws_iam_role.plan.name

  policy_arns = [data.aws_iam_policy.read_only.arn]
}

data "aws_iam_policy_document" "plan_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.terraform_plan_subject]
    }
  }
}

data "aws_iam_policy" "read_only" {
  name = "ReadOnlyAccess"
}

resource "aws_iam_role" "apply" {
  name        = "HomelabTerraformApply"
  description = "The role assumed by the Terraform Apply job in the akrantz01/homelab repository on GitHub"

  assume_role_policy = data.aws_iam_policy_document.apply_trust_policy.json
}

resource "aws_iam_role_policy_attachments_exclusive" "apply" {
  role_name = aws_iam_role.apply.name

  policy_arns = [
    data.aws_iam_policy.iam_full_access.arn,
    data.aws_iam_policy.s3_full_access.arn,
  ]
}

data "aws_iam_policy" "iam_full_access" {
  name = "IAMFullAccess"
}

data "aws_iam_policy" "s3_full_access" {
  name = "AmazonS3FullAccess"
}

data "aws_iam_policy_document" "apply_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.terraform_apply_subject]
    }
  }
}
