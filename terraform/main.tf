terraform {
  required_version = "~> 1.8.1"

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
