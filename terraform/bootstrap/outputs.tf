output "github_oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "The ARN of the GitHub Actions OIDC identity provider"
}

output "state_bucket" {
  value = {
    name        = aws_s3_bucket.state.bucket
    arn         = aws_s3_bucket.state.arn
    region      = aws_s3_bucket.state.region
    kms_key_arn = data.aws_kms_alias.s3.target_key_arn
  }
  description = "The bucket holding Terraform state"
}

output "project_state_policy_arn" {
  value       = aws_iam_policy.project_state.arn
  description = "The ARN of the policy granting projects access to their Terraform state"
}

output "project_boundary_policy_arn" {
  value       = aws_iam_policy.project_boundary.arn
  description = "The ARN of the permissions boundary for project roles"
}
