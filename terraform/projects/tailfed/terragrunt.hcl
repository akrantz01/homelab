include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "aws" {
  path = find_in_parent_folders("providers/aws.hcl")
}

dependency "github-actions" {
  config_path = "../../github-actions"

  skip_outputs = true
}

inputs = {
  # The artifacts bucket lives in us-east-1, not the default region
  aws_region = "us-east-1"
}
