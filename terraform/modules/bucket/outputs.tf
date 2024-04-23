output "name" {
  value       = aws_s3_bucket.bucket.id
  description = "The resulting bucket name"
}

output "policy" {
  value       = data.aws_iam_policy_document.policy.json
  description = "The policy for allowing read and write access to the bucket"
}
