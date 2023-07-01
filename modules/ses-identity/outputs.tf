output "group" {
  value       = aws_iam_group.ses.name
  description = "The name of the IAM group that has access to SES"
}
