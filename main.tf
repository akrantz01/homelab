terraform {
  required_version = "~> 1.7.3"

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

  cloud {
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
