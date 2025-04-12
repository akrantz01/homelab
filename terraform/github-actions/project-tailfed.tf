resource "aws_iam_role" "tailfed" {
  name        = "GitHubActionsTailfed"
  description = "The role assumed by the akrantz01/tailfed repository on GitHub."

  assume_role_policy = data.aws_iam_policy_document.tailfed_trust_policy.json
}

resource "aws_iam_role_policy" "tailfed_artifacts" {
  name = "GitHubActionsTailfedArtifacts"
  role = aws_iam_role.tailfed.id

  policy = data.aws_iam_policy_document.tailfed_artifacts_policy.json
}

data "aws_iam_policy_document" "tailfed_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
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
      values   = ["repo:akrantz01/tailfed:ref:refs/tags/*"]
    }
  }
}

data "aws_iam_policy_document" "tailfed_artifacts_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::tailfed-artifacts/*"]
  }
}
