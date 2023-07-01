module "krantz_dev_email" {
  source = "./modules/ses-identity"

  domain = "krantz.social"
}
