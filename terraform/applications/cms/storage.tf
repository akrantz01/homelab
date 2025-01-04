module "bucket" {
  source = "../../modules/bucket"

  prefix = "cms-krantz-dev"

  acl            = "private"
  public_objects = false
}

resource "aws_iam_policy" "bucket_policy" {
  name = "AssetBucketPolicy"
  path = "/services/cms/"

  description = "Policy for accessing the CMS asset bucket"
  policy      = data.aws_iam_policy_document.bucket_policy.json
}

data "aws_iam_policy_document" "bucket_policy" {
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
