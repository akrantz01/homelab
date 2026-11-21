# Generated into units as an override file so each provider can contribute its own
# required_providers entry. This is the single source of truth for the version.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.97.0"
    }
  }
}
