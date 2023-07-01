module "outline_user" {
  source = "./modules/user"

  name = "outline"
  path = "/services/"

  groups = [module.krantz_dev_email.group]
}
