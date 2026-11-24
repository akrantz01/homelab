locals {
  project_state_name    = "ProjectTerraformState"
  project_state_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.project_state_name}"
  project_boundary_name = "ProjectPermissionsBoundary"
  project_boundary_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.project_boundary_name}"
}

resource "aws_iam_policy" "project_state" {
  name        = local.project_state_name
  description = "Access to the Terraform state of the repository named by the role's Project tag"

  policy = data.aws_iam_policy_document.project_state.json
}

data "aws_iam_policy_document" "project_state" {
  statement {
    sid       = "StateList"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "StateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/projects/$${aws:PrincipalTag/Project}/target/*"]
  }

  statement {
    sid       = "StateEncryption"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [data.aws_kms_alias.s3.target_key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${aws_s3_bucket.state.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "project_boundary" {
  name        = local.project_boundary_name
  description = "Permissions boundary for projects, scoped by the role's Project and ProjectPrefix tags"

  policy = data.aws_iam_policy_document.project_boundary.json
}

data "aws_iam_policy_document" "project_boundary" {
  source_policy_documents = [data.aws_iam_policy_document.project_state.json]

  statement {
    sid     = "OwnResources"
    effect  = "Allow"
    actions = ["*"]
    resources = [
      "arn:aws:s3:::$${aws:PrincipalTag/ProjectPrefix}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/$${aws:PrincipalTag/ProjectPrefix}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/$${aws:PrincipalTag/ProjectPrefix}-*",
      "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:$${aws:PrincipalTag/ProjectPrefix}-*",
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:$${aws:PrincipalTag/ProjectPrefix}-*",
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/$${aws:PrincipalTag/ProjectPrefix}-*",
      "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/$${aws:PrincipalTag/ProjectPrefix}-*",
      "arn:aws:sqs:*:${data.aws_caller_identity.current.account_id}:$${aws:PrincipalTag/ProjectPrefix}-*",
      "arn:aws:sns:*:${data.aws_caller_identity.current.account_id}:$${aws:PrincipalTag/ProjectPrefix}-*",
      "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/$${aws:PrincipalTag/ProjectPrefix}-*",
      "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:$${aws:PrincipalTag/ProjectPrefix}-*",
    ]
  }

  statement {
    sid       = "DenyUnboundedRoles"
    effect    = "Deny"
    actions   = ["iam:CreateRole", "iam:PutRolePermissionsBoundary"]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "iam:PermissionsBoundary"
      values   = [local.project_boundary_arn]
    }
  }

  statement {
    sid       = "DenyBoundaryRemoval"
    effect    = "Deny"
    actions   = ["iam:DeleteRolePermissionsBoundary"]
    resources = ["*"]
  }

  statement {
    sid       = "DenyUsers"
    effect    = "Deny"
    actions   = ["iam:CreateUser", "iam:CreateAccessKey", "iam:CreateLoginProfile"]
    resources = ["*"]
  }

  statement {
    sid     = "DenyProjectIam"
    effect  = "Deny"
    actions = ["iam:*"]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/projects/*",
      local.project_state_arn,
      local.project_boundary_arn,
    ]
  }

  statement {
    sid       = "DenyForeignProjectTag"
    effect    = "Deny"
    actions   = ["iam:CreateRole", "iam:TagRole"]
    resources = ["*"]

    condition {
      test     = "StringNotEqualsIfExists"
      variable = "aws:RequestTag/Project"
      values   = ["$${aws:PrincipalTag/Project}"]
    }
  }

  statement {
    sid       = "DenyForeignProjectPrefixTag"
    effect    = "Deny"
    actions   = ["iam:CreateRole", "iam:TagRole"]
    resources = ["*"]

    condition {
      test     = "StringNotEqualsIfExists"
      variable = "aws:RequestTag/ProjectPrefix"
      values   = ["$${aws:PrincipalTag/ProjectPrefix}"]
    }
  }

  statement {
    sid       = "DenyProjectSessionTags"
    effect    = "Deny"
    actions   = ["sts:TagSession"]
    resources = ["*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:TagKeys"
      values   = ["Project", "ProjectPrefix"]
    }
  }
}
