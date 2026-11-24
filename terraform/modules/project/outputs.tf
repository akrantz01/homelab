output "role_arn" {
  value       = aws_iam_role.project.arn
  description = "The ARN of the role the project assumes"
}

output "state_key" {
  value       = local.state_key
  description = "The key of the project's Terraform state in the state bucket"
}
