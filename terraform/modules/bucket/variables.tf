variable "name" {
  type        = string
  description = "The name of the bucket"
}

variable "prefix" {
  type        = bool
  description = "Whether to use the name as a prefix for the bucket"
  default     = true
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

variable "policy" {
  type        = string
  nullable    = true
  default     = null
  description = "The resource policy to apply to the bucket"
}
