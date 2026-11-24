variable "repository" {
  type        = string
  description = "The name of the project's GitHub repository"
}

variable "prefix" {
  type        = string
  default     = null
  description = "The prefix of resource names the project may manage (defaults to the repository name)"
}

variable "refs" {
  type        = list(string)
  default     = []
  description = "The git refs allowed to assume the project's role (e.g. refs/heads/main, refs/tags/*)"
}

variable "environments" {
  type        = list(string)
  default     = []
  description = "The GitHub environments allowed to assume the project's role"

  validation {
    condition     = length(var.refs) + length(var.environments) > 0
    error_message = "At least one of refs or environments must be set."
  }
}

variable "policies" {
  type        = map(string)
  default     = {}
  description = "Inline policies (name => JSON document) granting the project's permissions, capped by its permissions boundary"
}

variable "policy_arns" {
  type        = list(string)
  default     = []
  description = "Managed policies to attach to the project's role, capped by its permissions boundary"
}

variable "github_oidc_provider_arn" {
  type        = string
  description = "The ARN of the GitHub Actions OIDC identity provider in AWS"
}

variable "boundary_policy_arn" {
  type        = string
  description = "The ARN of the shared permissions boundary for project roles"
}

variable "state_policy_arn" {
  type        = string
  description = "The ARN of the shared policy granting access to the Terraform state of the repository named by the role's Project tag"
}

variable "state_bucket" {
  type = object({
    name   = string
    region = string
  })
  description = "The bucket holding Terraform state"
}
