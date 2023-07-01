module "krantz_dev_email" {
  source = "./modules/ses-identity"

  domain = "krantz.dev"
}

module "krantz_social_email" {
  source = "./modules/ses-identity"

  domain = "krantz.social"
}
