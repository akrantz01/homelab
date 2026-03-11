terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.36.0"
    }
  }
}

module "user" {
  source = "../../modules/user"

  name = "outline"
  path = "/services/"
}
