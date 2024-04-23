provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "The region to deploy to for the AWS provider"
}
