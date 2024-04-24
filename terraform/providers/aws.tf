provider "aws" {
  region = var.aws_region
}

# tflint-ignore: terraform_standard_module_structure
variable "aws_region" {
  type        = string
  description = "The region to deploy to for the AWS provider"
}
