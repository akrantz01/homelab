module "storage" {
  source = "../../modules/bucket"

  name = "krantz-wiki"

  acl            = "private"
  public_objects = true
}

resource "aws_s3_bucket_cors_configuration" "storage" {
  bucket = module.storage.name

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

resource "aws_iam_user_policy" "storage" {
  user = module.user.name
  name = "FileStorage"

  policy = module.storage.policy
}
