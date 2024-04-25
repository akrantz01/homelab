provider "github" {
  owner = var.github_owner
  app_auth {
    id              = var.github_app.id
    installation_id = var.github_app.installation_id
    pem_file        = var.github_app.private_key
  }
}

# tflint-ignore: terraform_standard_module_structure
variable "github_owner" {
  type        = string
  description = "The owner of the GitHub repository"
}

# tflint-ignore: terraform_standard_module_structure
variable "github_app" {
  type = object({
    id              = string
    installation_id = string
    private_key     = string
  })
  description = "The GitHub App configuration"
}
