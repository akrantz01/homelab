# Generated into units as an override file so each provider can contribute its own
# required_providers entry. This is the single source of truth for the version.
terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.21.0"
    }
  }
}
