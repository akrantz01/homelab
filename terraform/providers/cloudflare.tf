provider "cloudflare" {
  api_token = var.cloudflare_token
}

variable "cloudflare_token" {
  type        = string
  description = "The token for authenticating with the Cloudflare API"
}
