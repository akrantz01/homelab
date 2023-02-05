terraform {
  required_version = "~> 1.3.7"
  required_providers {
    aws   = "~> 4.53.0"
    local = "~> 2.3.0"
    tls   = "~> 4.0.4"

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.33.1"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = "homelab"
      App     = "evil-lair"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
