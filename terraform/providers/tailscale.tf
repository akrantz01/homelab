provider "tailscale" {
  tailnet = var.tailscale_tailnet
}

# tflint-ignore: terraform_standard_module_structure
variable "tailscale_tailnet" {
  type        = string
  description = "The tailnet to use for Tailscale"
}
