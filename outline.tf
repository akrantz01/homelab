module "outline_user" {
  source = "./modules/user"

  name = "outline"
  path = "/services/"

  groups = [module.krantz_dev_email.group]
}

resource "aws_s3_bucket" "outline" {
  bucket_prefix = "krantz-wiki-"
}

resource "aws_s3_bucket_ownership_controls" "outline" {
  bucket = aws_s3_bucket.outline.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "outline" {
  bucket = aws_s3_bucket.outline.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "outline" {
  bucket = aws_s3_bucket.outline.id
  acl    = "private"
}

resource "aws_s3_bucket_cors_configuration" "outline" {
  bucket = aws_s3_bucket.outline.id

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

data "aws_iam_policy_document" "outline" {
  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = ["${aws_s3_bucket.outline.arn}/*"]
  }
}

resource "aws_iam_user_policy" "outline" {
  user = module.outline_user.name
  name = "FileStorage"

  policy = data.aws_iam_policy_document.outline.json
}
