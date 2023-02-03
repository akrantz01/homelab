variable "region" {
  type        = string
  description = "The region to deploy the instance in"
}

variable "enable_ssh" {
  type        = bool
  description = "Whether to allow SSH connectivity"
  default     = false
}
