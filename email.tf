module "krantz_social_email" {
  source = "./modules/ses-identity"

  domain = "krantz.social"
}
