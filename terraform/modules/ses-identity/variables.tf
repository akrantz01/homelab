variable "domain" {
  type        = string
  description = "The domain for the SES identity"
}

variable "configuration_set" {
  type        = string
  description = "The configuration set name to use as default"
}
