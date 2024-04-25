variable "state_bucket" {
  type        = string
  description = "The name of the S3 bucket to store the Terraform state file in"
}

variable "state_lock_table" {
  type        = string
  description = "The name of the DynamoDB table to use for state locking"
}
