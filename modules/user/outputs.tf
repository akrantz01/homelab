output "access_key_id" {
  value       = aws_iam_access_key.user.id
  description = "The AWS access key ID"
}

output "secret_access_key" {
  value       = aws_iam_access_key.user.secret
  description = "The AWS secret access key"
}
