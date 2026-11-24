provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.aws_default_tags
  }
}

# tflint-ignore: terraform_standard_module_structure
variable "aws_region" {
  type        = string
  description = "The region to deploy to for the AWS provider"
}

# tflint-ignore: terraform_standard_module_structure
variable "aws_default_tags" {
  type        = map(string)
  description = "The tags applied to every resource created by the AWS provider"
}
