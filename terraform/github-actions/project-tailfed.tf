resource "aws_iam_role" "tailfed" {
  name        = "GitHubActionsTailfed"
  description = "The role assumed by the akrantz01/tailfed repository on GitHub."

  assume_role_policy = data.aws_iam_policy_document.tailfed_trust_policy.json
}

resource "aws_iam_role_policy" "tailfed_ecr" {
  name = "GitHubActionsTailfedECR"
  role = aws_iam_role.tailfed.id

  policy = data.aws_iam_policy_document.tailfed_ecr_policy.json
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
      values   = ["repo:akrantz01/tailfed:ref:refs/heads/*"]
    }
  }
}

data "aws_iam_policy_document" "tailfed_ecr_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr-public:GetAuthorizationToken",
      "sts:GetServiceBearerToken",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr-public:BatchCheckLayerAvailability",
      "ecr-public:CompleteLayerUpload",
      "ecr-public:InitiateLayerUpload",
      "ecr-public:PutImage",
      "ecr-public:UploadLayerPart",
    ]
    resources = [
      "arn:aws:ecr-public::${data.aws_caller_identity.current.account_id}:repository/tailfed/*"
    ]
  }
}
