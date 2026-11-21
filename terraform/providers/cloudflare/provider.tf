provider "cloudflare" {
  api_token = var.cloudflare_token
}

# tflint-ignore: terraform_standard_module_structure
variable "cloudflare_token" {
  type        = string
  description = "The token for authenticating with the Cloudflare API"
}
