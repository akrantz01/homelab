resource "aws_s3_bucket" "artifacts" {
  bucket = "tailfed-artifacts"
}

resource "aws_s3_bucket_ownership_controls" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "artifacts" {
  depends_on = [
    aws_s3_bucket_ownership_controls.artifacts,
    aws_s3_bucket_public_access_block.artifacts
  ]

  bucket = aws_s3_bucket.artifacts.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  policy = data.aws_iam_policy_document.artifacts.json
}

data "aws_iam_policy_document" "artifacts" {
  statement {
    sid     = "AllowGetObject"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.artifacts.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
