terraform {
  required_version = "~> 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.30.0"
    }
  }

  cloud {
    hostname     = "app.terraform.io"
    organization = "krantz"
    workspaces {
      name = "homelab"
    }
  }
}

provider "aws" {
  region = var.regions.aws
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}
