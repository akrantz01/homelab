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
  }
}

# TODO: import ovh and backblaze resources
