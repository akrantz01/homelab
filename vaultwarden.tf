module "vaultwarden_user" {
  source = "./modules/user"

  name = "vaultwarden"
  path = "/services/"

  groups = [module.krantz_dev_email.group]
}
