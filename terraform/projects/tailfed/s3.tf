resource "aws_s3_bucket" "global_artifacts" {
  bucket = "tailfed-artifacts"
}

moved {
  from = aws_s3_bucket.artifacts
  to = aws_s3_bucket.global_artifacts
}

resource "aws_s3_bucket_ownership_controls" "global_artifacts" {
  bucket = aws_s3_bucket.global_artifacts.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

moved {
  from = aws_s3_bucket_ownership_controls.artifacts
  to = aws_s3_bucket_ownership_controls.global_artifacts
}

resource "aws_s3_bucket_public_access_block" "global_artifacts" {
  bucket = aws_s3_bucket.global_artifacts.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

moved {
  from = aws_s3_bucket_public_access_block.artifacts
  to = aws_s3_bucket_public_access_block.global_artifacts
}

resource "aws_s3_bucket_acl" "global_artifacts" {
  depends_on = [
    aws_s3_bucket_ownership_controls.global_artifacts,
    aws_s3_bucket_public_access_block.global_artifacts
  ]

  bucket = aws_s3_bucket.global_artifacts.id
  acl    = "public-read"
}

moved {
  from = aws_s3_bucket_acl.artifacts
  to = aws_s3_bucket_acl.global_artifacts
}

resource "aws_s3_bucket_policy" "global_artifacts" {
  bucket = aws_s3_bucket.global_artifacts.id

  policy = data.aws_iam_policy_document.global_artifacts.json
}

moved {
  from = aws_s3_bucket_policy.artifacts
  to = aws_s3_bucket_policy.global_artifacts
}

data "aws_iam_policy_document" "global_artifacts" {
  statement {
    sid       = "AllowGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.global_artifacts.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
