variable "region" {
  type        = string
  description = "The region to deploy the instance in"
}

variable "enable_ssh" {
  type        = bool
  description = "Whether to allow SSH connectivity"
  default     = false
}

variable "domain" {
  type        = string
  description = "The base domain the instance should be accessible at"
}

variable "subdomain" {
  type        = string
  description = "The subdomain on the base domain the instance should be accessible at"
}

variable "letsencrypt_email" {
  type        = string
  description = "The email address to use for Let's Encrypt"
}

variable "letsencrypt_staging" {
  type        = bool
  description = "Whether to use the Let's Encrypt staging environment"
  default     = false
}

variable "cloudflare_api_token" {
  type        = string
  description = "The Cloudflare API token to use, must have the following permissions: Zone.Zone, Zone.DNS"
}
