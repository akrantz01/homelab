variable "state_bucket" {
  type        = string
  description = "The name of the S3 bucket holding the Terraform state"
}

variable "state_lock_table" {
  type        = string
  description = "The name of the DynamoDB table holding the Terraform state locks"
}
