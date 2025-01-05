module "bucket" {
  source = "../../modules/bucket"

  prefix = "cms-krantz-dev"

  acl            = "private"
  public_objects = true
}

resource "aws_s3_bucket_policy" "cms" {
  bucket = module.bucket.name
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_iam_policy" "bucket_readwrite_policy" {
  name = "AssetBucketReadWritePolicy"
  path = "/services/cms/"

  description = "Policy for accessing the CMS asset bucket"
  policy      = data.aws_iam_policy_document.bucket_readwrite_policy.json
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${module.bucket.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

data "aws_iam_policy_document" "bucket_readwrite_policy" {
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetObjectAcl",
      "s3:PutObjectAcl",
    ]
    resources = ["${module.bucket.arn}/*"]
  }
}
