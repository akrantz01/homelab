terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.72.0"
    }
  }
}

module "user" {
  source = "../../modules/user"

  name = "outline"
  path = "/services/"
}
