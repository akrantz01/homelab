terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.97.0"
    }
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket        = !var.prefix ? var.name : null
  bucket_prefix = var.prefix ? "${var.name}-" : null
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = !var.public_objects
  block_public_policy     = !var.public_objects
  ignore_public_acls      = !var.public_objects
  restrict_public_buckets = !var.public_objects
}

resource "aws_s3_bucket_acl" "bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.bucket,
    aws_s3_bucket_public_access_block.bucket
  ]

  bucket = aws_s3_bucket.bucket.id
  acl    = var.acl
}

resource "aws_s3_bucket_policy" "bucket" {
  count = var.policy != null ? 1 : 0

  bucket = aws_s3_bucket.bucket.id
  policy = var.policy
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
  }
}
