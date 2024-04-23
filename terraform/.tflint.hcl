plugin "terraform" {
  enabled = true
  version = "0.6.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

plugin "aws" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "google" {
    enabled = true
    version = "0.27.1"
    source  = "github.com/terraform-linters/tflint-ruleset-google"
}