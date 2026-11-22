terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.30.0"
    }
  }
}

provider "github" {}

provider "tailscale" {}
