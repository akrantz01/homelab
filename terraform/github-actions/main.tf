terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.88.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.6.0"
    }
  }
}

data "aws_caller_identity" "current" {}
