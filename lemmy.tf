module "lemmy_user" {
  source = "./modules/user"

  name = "lemmy"
  path = "/services/"

  groups = [module.krantz_social_email.group]
}

module "lemmy_pictrs_bucket" {
  source = "./modules/bucket"

  prefix = "krantz-lemmy-pictrs"

  acl = "private"
  public_objects = true
}

resource "aws_iam_user_policy" "lemmy_pictrs" {
  user = module.lemmy_user.name
  name = "FileStorage"

  policy = module.lemmy_pictrs_bucket.policy
}
