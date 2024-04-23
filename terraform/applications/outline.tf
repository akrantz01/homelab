module "outline_user" {
  source = "../modules/user"

  name = "outline"
  path = "/services/"

  groups = [module.krantz_dev_email.group]
}

module "outline_bucket" {
  source = "../modules/bucket"

  prefix = "krantz-wiki"

  acl            = "private"
  public_objects = true
}

resource "aws_s3_bucket_cors_configuration" "outline" {
  bucket = module.outline_bucket.name

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST", "PUT"]
    allowed_origins = ["https://wiki.krantz.dev"]
    expose_headers  = []
  }

  cors_rule {
    allowed_headers = []
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
  }
}

resource "aws_iam_user_policy" "outline" {
  user = module.outline_user.name
  name = "FileStorage"

  policy = module.outline_bucket.policy
}
