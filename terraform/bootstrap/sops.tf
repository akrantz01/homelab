resource "aws_kms_key" "sops" {
  description = "For use with the SOPS (https://github.com/getsops/sops) tool."

  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

resource "aws_kms_alias" "sops" {
  name          = "alias/sops"
  target_key_id = aws_kms_key.sops.key_id
}

resource "aws_kms_key_policy" "sops" {
  key_id = aws_kms_key.sops.key_id
  policy = data.aws_iam_policy_document.sops_key_policy.json
}

data "aws_iam_policy_document" "sops_key_policy" {
  statement {
    sid = "RootUserPermissions"

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid = "GitHubActions"

    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.plan.arn,
        aws_iam_role.apply.arn,
        # TODO: remove once management github-actions is cleaned up
        "arn:aws:iam::416515258441:role/GitHubActionsHomelab",
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}
