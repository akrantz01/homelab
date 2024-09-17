terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.67.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.41.0"
    }
  }
}

resource "aws_sesv2_configuration_set" "default" {
  configuration_set_name = "default"

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

module "krantz_cloud" {
  source = "../modules/ses-identity"

  domain = "krantz.cloud"

  configuration_set = aws_sesv2_configuration_set.default.id
}

module "krantz_dev" {
  source = "../modules/ses-identity"

  domain = "krantz.dev"

  configuration_set = aws_sesv2_configuration_set.default.id
}

module "krantz_social" {
  source = "../modules/ses-identity"

  domain = "krantz.social"

  configuration_set = aws_sesv2_configuration_set.default.id
}
