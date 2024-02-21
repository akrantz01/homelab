terraform {
  required_version = "~> 1.7.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.37.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.25.0"
    }
  }
}

resource "aws_sesv2_email_identity" "domain" {
  email_identity = var.domain

  configuration_set_name = var.configuration_set
}

resource "cloudflare_record" "dkim" {
  count = 3

  zone_id = data.cloudflare_zone.domain.id

  type  = "CNAME"
  name  = "${element(aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens, count.index)}._domainkey.${var.domain}"
  value = "${element(aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens, count.index)}.dkim.amazonses.com"

  proxied = false
  comment = "AWS SES DKIM verification"
}

locals {
  domain_pascal_case = join("", [for segment in split(".", var.domain) : title(segment)])
}

resource "aws_iam_group" "ses" {
  name = "SendEmailFor${local.domain_pascal_case}"
  path = "/ses/"
}

data "aws_iam_policy_document" "ses" {
  statement {
    sid = "AllowSesSending"

    effect  = "Allow"
    actions = ["ses:SendRawEmail"]
    resources = [
      "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:configuration-set/${var.configuration_set}",
      "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:identity/${var.domain}"
    ]
  }
}

resource "aws_iam_group_policy" "ses" {
  name  = "AllowSendingForDomain"
  group = aws_iam_group.ses.name

  policy = data.aws_iam_policy_document.ses.json
}
