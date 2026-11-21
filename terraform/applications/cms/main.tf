terraform {
  required_providers {
    # Still needed to destroy resources left in state; remove this unit once that has been applied
    # tflint-ignore: terraform_unused_required_providers
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.97.0"
    }
  }
}
