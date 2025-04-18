provider "tailscale" {
  tailnet = var.tailscale_tailnet

  oauth_client_id     = var.tailscale_oauth_client_id
  oauth_client_secret = var.tailscale_oauth_client_secret
  scopes              = var.tailscale_oauth_scopes
}

# tflint-ignore: terraform_standard_module_structure
variable "tailscale_tailnet" {
  type        = string
  description = "The tailnet to use for Tailscale"
}

# tflint-ignore: terraform_standard_module_structure
variable "tailscale_oauth_client_id" {
  type        = string
  description = "The OAuth client ID for authenticating with Tailscale"
}

# tflint-ignore: terraform_standard_module_structure
variable "tailscale_oauth_client_secret" {
  type        = string
  description = "The OAuth client secret for authenticating with Tailscale"
}

# tflint-ignore: terraform_standard_module_structure
variable "tailscale_oauth_scopes" {
  type        = list(string)
  default     = []
  description = "The OAuth scopes required for authenticating with Tailscale"
}
