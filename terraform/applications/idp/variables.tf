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

variable "public_subnets" {
  description = "The available public subnet IDs."
  type        = list(string)
}

variable "vpc_id" {
  description = "The VPC ID. Must contain the public subnets."
  type        = string
}
