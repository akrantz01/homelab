include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "aws" {
  path = find_in_parent_folders("providers/aws.hcl")
}

include "github" {
  path = find_in_parent_folders("providers/github.hcl")
}
