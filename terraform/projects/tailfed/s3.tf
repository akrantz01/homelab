module "artifacts" {
  source = "../../modules/bucket"

  name   = "tailfed-artifacts"
  prefix = false

  acl            = "public-read"
  public_objects = true

  policy = data.aws_iam_policy_document.artifacts.json
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
