include "root" {
  path = find_in_parent_folders()
}

include "aws" {
  path = find_in_parent_folders("aws.hcl")
}

dependency "github-actions" {
  config_path = "../../github-actions"

  skip_outputs = true
}

dependency "email" {
  config_path = "../../email"
}

inputs = {
  email_groups = {
    krantz_dev = dependency.email.outputs.krantz_dev
  }
}
