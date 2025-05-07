variable "flake" {
  description = "The flake to use for the instance."
  type        = string
}

variable "host_key" {
  description = "The SSH host key to use. Must be set up to decrypt SOPS secrets."
  type = object({
    private = string
    public  = string
  })
}

variable "subnet_id" {
  description = "The subnet ID to launch the instance in."
  type        = string
}
