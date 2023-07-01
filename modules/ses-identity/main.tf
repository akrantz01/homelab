terraform {
  required_version = "~> 1.5.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.6.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.9.0"
    }
  }
}

data "aws_region" "current" {}

data "cloudflare_zone" "domain" {
  name = var.domain
}

resource "aws_sesv2_configuration_set" "default" {
  configuration_set_name = replace(var.domain, ".", "-")

  delivery_options {
    tls_policy = "OPTIONAL"
  }

  reputation_options {
    reputation_metrics_enabled = true
  }

  sending_options {
    sending_enabled = true
  }
}

resource "aws_sesv2_email_identity" "domain" {
  email_identity = var.domain

  configuration_set_name = aws_sesv2_configuration_set.default.configuration_set_name
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
