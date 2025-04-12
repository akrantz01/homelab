resource "aws_s3_bucket" "artifacts" {
  bucket = "tailfed-artifacts"
}

moved {
  from = aws_s3_bucket.global_artifacts
  to = aws_s3_bucket.artifacts
}

resource "aws_s3_bucket_ownership_controls" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

moved {
  from = aws_s3_bucket_ownership_controls.global_artifacts
  to = aws_s3_bucket_ownership_controls.artifacts
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

moved {
  from = aws_s3_bucket_public_access_block.global_artifacts
  to = aws_s3_bucket_public_access_block.artifacts
}

resource "aws_s3_bucket_acl" "artifacts" {
  depends_on = [
    aws_s3_bucket_ownership_controls.artifacts,
    aws_s3_bucket_public_access_block.artifacts
  ]

  bucket = aws_s3_bucket.artifacts.id
  acl    = "public-read"
}

moved {
  from = aws_s3_bucket_acl.global_artifacts
  to = aws_s3_bucket_acl.artifacts
}

resource "aws_s3_bucket_policy" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  policy = data.aws_iam_policy_document.artifacts.json
}

moved {
  from = aws_s3_bucket_policy.global_artifacts
  to = aws_s3_bucket_policy.artifacts
}

data "aws_iam_policy_document" "artifacts" {
  statement {
    sid       = "AllowGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.artifacts.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
