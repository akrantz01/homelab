terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.65.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.2.1"
    }
  }
}

data "aws_caller_identity" "current" {}
