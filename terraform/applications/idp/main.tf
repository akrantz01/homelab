terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.97.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.9.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2"
    }
  }
}

locals {
  zone   = "krantz.dev"
  domain = "login.${local.zone}"
}

data "cloudflare_zone" "domain" {
  filter = {
    name = local.zone
  }
}
