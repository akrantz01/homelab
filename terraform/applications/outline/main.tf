terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.67.0"
    }
  }
}

module "user" {
  source = "../../modules/user"

  name = "outline"
  path = "/services/"

  groups = [var.email_groups.krantz_dev]
}
