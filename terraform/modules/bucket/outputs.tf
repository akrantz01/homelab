output "name" {
  value       = aws_s3_bucket.bucket.id
  description = "The resulting bucket name"
}

output "arn" {
  value       = aws_s3_bucket.bucket.arn
  description = "The resulting bucket ARN"
}

output "domain_name" {
  value       = aws_s3_bucket.bucket.bucket_regional_domain_name
  description = "The resulting bucket domain name"
}

output "policy" {
  value       = data.aws_iam_policy_document.policy.json
  description = "The policy for allowing read and write access to the bucket"
}
