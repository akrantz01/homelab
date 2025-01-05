module "user" {
  source = "../../modules/user"

  name = "cms"
  path = "/services/"

  policies = {
    "AssetBucketReadWritePolicy" = aws_iam_policy.bucket_readwrite_policy.arn
    "CdnCacheInvalidationPolicy" = aws_iam_policy.cdn_cache_invalidation.arn
  }
}
