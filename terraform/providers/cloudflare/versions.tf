# Generated into units as an override file so each provider can contribute its own
# required_providers entry. This is the single source of truth for the version.
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.9.0"
    }
  }
}
