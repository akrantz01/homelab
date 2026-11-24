variable "github_oidc_provider_arn" {
  type        = string
  description = "The ARN of the GitHub Actions OIDC identity provider in AWS"
}

variable "state_bucket" {
  type = object({
    name   = string
    region = string
  })
  description = "The bucket holding Terraform state"
}

variable "state_policy_arn" {
  type        = string
  description = "The ARN of the shared policy granting projects access to their Terraform state"
}

variable "boundary_policy_arn" {
  type        = string
  description = "The ARN of the shared permissions boundary for project roles"
}
