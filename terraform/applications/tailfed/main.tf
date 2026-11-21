terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.97.0"
    }
    # Still needed to destroy tailfed v1 resources left in state; remove once that has been applied
    # tflint-ignore: terraform_unused_required_providers
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.9.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.21.0"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# TODO: re-enable with tailfed v2 on GCP
# module "tailfed" {
#   # tflint-ignore: terraform_module_pinned_source
#   source = "github.com/akrantz01/tailfed//terraform?ref=v1.2.0"
#   providers = {
#     aws.release = aws.us_east_1
#   }
#
#   region = var.aws_region
#
#   release_version = "nightly"
#
#   tailscale_tailnet  = var.tailscale_tailnet
#   tailscale_auth_key = aws_ssm_parameter.auth_key.arn
#
#   tailscale_oauth = {
#     client_id     = aws_ssm_parameter.oauth_client_id.arn
#     client_secret = aws_ssm_parameter.oauth_client_secret.arn
#   }
#
#   domain = {
#     name        = local.domain
#     certificate = aws_acm_certificate.domain.arn
#   }
#
#   execution_role_policies = {
#     Secrets = data.aws_iam_policy_document.secrets_access.json
#   }
# }
