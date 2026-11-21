terraform {
  required_providers {
    # Still needed for destruction
    # tflint-ignore: terraform_unused_required_providers
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.97.0"
    }
  }
}
