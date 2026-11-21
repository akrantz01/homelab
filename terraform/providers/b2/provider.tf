provider "b2" {
  application_key    = var.b2_application_key
  application_key_id = var.b2_application_key_id
}

# tflint-ignore: terraform_standard_module_structure
variable "b2_application_key" {
  type        = string
  description = "The application key for authenticating with the Backblaze B2 API"
}

# tflint-ignore: terraform_standard_module_structure
variable "b2_application_key_id" {
  type        = string
  description = "The application key ID for authenticating with the Backblaze B2 API"
}
