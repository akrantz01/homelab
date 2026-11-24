terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.73.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
  }
}

data "github_repository" "project" {
  name = var.repository
}

locals {
  state_key = "projects/${var.repository}/target/terraform.tfstate"
}
