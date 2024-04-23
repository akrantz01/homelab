variable "prefix" {
  type        = string
  description = "The prefix to generate the name with"
}

variable "acl" {
  type        = string
  default     = "private"
  description = "The ACL to apply to the bucket"
}

variable "public_objects" {
  type        = bool
  default     = false
  description = "Whether the objects can be public"
}
