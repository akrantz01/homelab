terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.72.0"
    }
    b2 = {
      source  = "Backblaze/b2"
      version = "0.9.0"
    }
  }
}

resource "b2_bucket" "storage" {
  bucket_type = "allPrivate"
  bucket_name = "watch-krantz-dev"

  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
}

module "email_user" {
  source = "../../modules/user"

  name = "watch"
  path = "/services/"

  groups = [var.email_groups.krantz_dev]
}
