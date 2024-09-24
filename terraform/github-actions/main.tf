terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.68.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.3.0"
    }
  }
}

data "aws_caller_identity" "current" {}
