module "lemmy_user" {
  source = "./modules/user"

  name = "lemmy"
  path = "/services/"

  groups = [module.krantz_social_email.group]
}

resource "aws_s3_bucket" "lemmy_pictrs" {
  bucket_prefix = "krantz-lemmy-pictrs-"
}

resource "aws_s3_bucket_ownership_controls" "lemmy_pictrs" {
  bucket = aws_s3_bucket.lemmy_pictrs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "lemmy_pictrs" {
  bucket = aws_s3_bucket.lemmy_pictrs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "lemmy_pictrs" {
  bucket = aws_s3_bucket.outline.id
  acl    = "private"
}

data "aws_iam_policy_document" "lemmy_pictrs" {
  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = ["${aws_s3_bucket.lemmy_pictrs.arn}/*"]
  }
}

resource "aws_iam_user_policy" "lemmy_pictrs" {
  user = module.lemmy_user.name
  name = "FileStorage"

  policy = data.aws_iam_policy_document.lemmy_pictrs.json
}
