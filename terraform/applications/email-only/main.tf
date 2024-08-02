terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.61.0"
    }
  }
}

module "authelia_user" {
  source = "../../modules/user"

  name = "authelia"
  path = "/services/"

  groups = [var.email_groups.krantz_dev]
}

module "firefly_user" {
  source = "../../modules/user"

  name = "firefly"
  path = "/services/"

  groups = [var.email_groups.krantz_dev]
}

module "mealie_user" {
  source = "../../modules/user"

  name = "mealie"
  path = "/services/"

  groups = [var.email_groups.krantz_dev]
}

module "ntfy_user" {
  source = "../../modules/user"

  name = "ntfy"
  path = "/services/"

  groups = [var.email_groups.krantz_dev, var.email_groups.krantz_cloud]
}

module "vaultwarden_user" {
  source = "../../modules/user"

  name = "vaultwarden"
  path = "/services/"

  groups = [var.email_groups.krantz_dev]
}
