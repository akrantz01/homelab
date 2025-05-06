resource "aws_iam_role" "homelab" {
  name        = "GitHubActionsHomelab"
  description = "The role assumed by the akrantz01/homelab repository on GitHub."

  assume_role_policy = data.aws_iam_policy_document.homelab_trust_policy.json
}

resource "aws_iam_role_policy_attachments_exclusive" "homelab" {
  role_name = aws_iam_role.homelab.name

  policy_arns = [
    data.aws_iam_policy.dynamodb_full_access.arn,
    data.aws_iam_policy.iam_full_access.arn,
    data.aws_iam_policy.kms_full_access.arn,
    data.aws_iam_policy.s3_full_access.arn,
    data.aws_iam_policy.ses_full_access.arn,
    data.aws_iam_policy.cloudfront_full_access.arn,
    data.aws_iam_policy.ssm_full_access.arn,
    data.aws_iam_policy.lambda_full_access.arn,
    data.aws_iam_policy.scheduler_full_access.arn,
    data.aws_iam_policy.events_full_access.arn,
    data.aws_iam_policy.step_functions_full_access.arn,
    data.aws_iam_policy.acm_full_access.arn,
    data.aws_iam_policy.api_gateway_full_access.arn,
    data.aws_iam_policy.ec2_full_access.arn,
  ]
}

resource "aws_iam_role_policy" "homelab_kms_ssm" {
  role   = aws_iam_role.homelab.id
  name   = "KMSForSSM"
  policy = data.aws_iam_policy_document.kms_ssm.json
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

data "aws_iam_policy_document" "kms_ssm" {
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:Encrypt"]
    resources = ["*"]
  }
}

data "aws_iam_policy" "dynamodb_full_access" {
  name = "AmazonDynamoDBFullAccess"
}

data "aws_iam_policy" "iam_full_access" {
  name = "IAMFullAccess"
}

data "aws_iam_policy" "kms_full_access" {
  name = "AWSKeyManagementServicePowerUser"
}

data "aws_iam_policy" "s3_full_access" {
  name = "AmazonS3FullAccess"
}

data "aws_iam_policy" "ses_full_access" {
  name = "AmazonSESFullAccess"
}

data "aws_iam_policy" "cloudfront_full_access" {
  name = "CloudFrontFullAccess"
}

data "aws_iam_policy" "ssm_full_access" {
  name = "AmazonSSMFullAccess"
}

data "aws_iam_policy" "lambda_full_access" {
  name = "AWSLambda_FullAccess"
}

data "aws_iam_policy" "scheduler_full_access" {
  name = "AmazonEventBridgeSchedulerFullAccess"
}

data "aws_iam_policy" "events_full_access" {
  name = "CloudWatchEventsFullAccess"
}

data "aws_iam_policy" "step_functions_full_access" {
  name = "AWSStepFunctionsFullAccess"
}

data "aws_iam_policy" "acm_full_access" {
  name = "AWSCertificateManagerFullAccess"
}

data "aws_iam_policy" "api_gateway_full_access" {
  name = "AmazonAPIGatewayAdministrator"
}

data "aws_iam_policy" "ec2_full_access" {
  name = "AmazonEC2FullAccess"
}
