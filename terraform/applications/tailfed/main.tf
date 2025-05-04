terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.97.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.2.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.19.0"
    }
  }
}

locals {
  zone   = "krantz.cloud"
  domain = "tailfed.${local.zone}"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

module "tailfed" {
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/akrantz01/tailfed//terraform?ref=main"
  providers = {
    aws.release = aws.us_east_1
  }

  region = var.aws_region

  release_version = "nightly"

  tailscale_tailnet  = var.tailscale_tailnet
  tailscale_auth_key = aws_ssm_parameter.auth_key.arn

  tailscale_oauth = {
    client_id     = aws_ssm_parameter.oauth_client_id.arn
    client_secret = aws_ssm_parameter.oauth_client_secret.arn
  }

  domain = {
    name        = local.domain
    certificate = aws_acm_certificate.domain.arn
  }

  execution_role_policies = {
    Secrets = data.aws_iam_policy_document.secrets_access.json
  }
}

resource "aws_iam_openid_connect_provider" "tailfed" {
  depends_on = [module.tailfed]

  url = "https://${local.domain}"

  client_id_list = ["sts.amazonaws.com"]
}
