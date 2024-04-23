###
### Services that only require email
###

module "authelia_user" {
  source = "../modules/user"

  name = "authelia"
  path = "/services/"

  groups = [module.krantz_dev_email.group]
}

module "firefly_user" {
  source = "../modules/user"

  name = "firefly"
  path = "/services/"

  groups = [module.krantz_dev_email.group]
}

module "mealie_user" {
  source = "../modules/user"

  name = "mealie"
  path = "/services/"

  groups = [module.krantz_dev_email.group]
}

module "ntfy_user" {
  source = "../modules/user"

  name = "ntfy"
  path = "/services/"

  groups = [module.krantz_dev_email.group, module.krantz_cloud_email.group]
}

module "vaultwarden_user" {
  source = "../modules/user"

  name = "vaultwarden"
  path = "/services/"

  groups = [module.krantz_dev_email.group]
}

