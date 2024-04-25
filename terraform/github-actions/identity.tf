data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "homelab" {
  name        = "GitHubActionsHomelab"
  description = "The role assumed by the akrantz01/homelab repository on GitHub."

  assume_role_policy = data.aws_iam_policy_document.homelab_trust_policy.json
}

data "aws_iam_policy_document" "homelab_trust_policy" {
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
      values   = ["repo:akrantz01/homelab:ref:refs/heads/*"]
    }
  }
}

resource "aws_iam_role_policy" "homelab_terraform_state_management" {
  name = "TerraformStateManagement"
  role = aws_iam_role.homelab.id

  policy = data.aws_iam_policy_document.homelab_terraform_state_management.json
}

data "aws_iam_policy_document" "homelab_terraform_state_management" {
  statement {
    sid = "LockTable"

    effect    = "Allow"
    actions   = ["dynamodb:DescribeTable", "dynamodb:UpdateTable", "dynamodb:TagResource"]
    resources = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.state_lock_table}"]
  }

  statement {
    sid = "StorageBucket"

    effect = "Allow"
    actions = [
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketTagging",
      "s3:PutBucketTagging",
      "s3:GetBucketLogging",
      "s3:PutBucketLogging",
      "s3:CreateBucket",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:PutEncryptionConfiguration",
      "s3:GetEncryptionConfiguration"
    ]
    resources = ["arn:aws:s3:::${var.state_bucket}"]
  }
}

resource "aws_iam_role_policy" "homelab_terraform_state_use" {
  name = "TerraformStateUse"
  role = aws_iam_role.homelab.id

  policy = data.aws_iam_policy_document.homelab_terraform_state_use.json
}

data "aws_iam_policy_document" "homelab_terraform_state_use" {
  statement {
    sid = "StateLocking"

    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.state_lock_table}"]
  }

  statement {
    sid = "StorageList"

    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket}"]
  }

  statement {
    sid = "StorageReadWrite"

    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${var.state_bucket}/*"]
  }
}
