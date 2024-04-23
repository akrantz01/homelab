variable "regions" {
  type = object({
    aws = string
  })
  default = {
    aws = "us-east-1"
  }
  description = "The regions to deploy to for each provider"
}

variable "cloudflare_token" {
  type        = string
  description = "The token for authenticating with the Cloudflare API"
}
