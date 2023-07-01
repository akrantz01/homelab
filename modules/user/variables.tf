variable "name" {
  type        = string
  description = "The user's name"
}

variable "path" {
  type        = string
  default     = null
  description = "The path in which to create the user"
}

variable "groups" {
  type        = list(string)
  default     = []
  description = "The groups to which the user should belong"
}

variable "policies" {
  type        = list(string)
  default     = []
  description = "The policy ARNs to attach to the user"
}
