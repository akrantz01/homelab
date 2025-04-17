# TODO: remove these variables once the Tailscale provider supports creating OAuth clients
variable "tailfed_tailscale_oauth_client_id" {
  type        = string
  description = "The OAuth client ID for authenticating tailfed with Tailscale"
}

variable "tailfed_tailscale_oauth_client_secret" {
  type        = string
  description = "The OAuth client secret for authenticating tailfed with Tailscale"
}
