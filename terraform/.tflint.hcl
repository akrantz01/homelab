config {
  call_module_type = "all"
}

plugin "terraform" {
  enabled = true
  version = "0.11.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

plugin "aws" {
  enabled = true
  version = "0.39.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "google" {
  enabled = true
  version = "0.31.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

# Handled by terragrunt
rule "terraform_required_version" {
  enabled = false
}
