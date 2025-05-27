module "artifacts" {
  source = "../../modules/bucket"

  name   = "tailfed-artifacts"
  prefix = false

  acl            = "public-read"
  public_objects = true

  policy = data.aws_iam_policy_document.artifacts.json
}

moved {
  from = aws_s3_bucket.artifacts
  to   = module.artifacts.aws_s3_bucket.bucket
}

moved {
  from = aws_s3_bucket_ownership_controls.artifacts
  to   = module.artifacts.aws_s3_bucket_ownership_controls.bucket
}

moved {
  from = aws_s3_bucket_public_access_block.artifacts
  to   = module.artifacts.aws_s3_bucket_public_access_block.bucket
}

moved {
  from = aws_s3_bucket_acl.artifacts
  to   = module.artifacts.aws_s3_bucket_acl.bucket
}

moved {
  from = aws_s3_bucket_policy.artifacts
  to   = module.artifacts.aws_s3_bucket_policy.bucket[0]
}

data "aws_iam_policy_document" "artifacts" {
  statement {
    sid       = "AllowGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${module.artifacts.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
