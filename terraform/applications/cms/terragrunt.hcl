include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "aws" {
  path = find_in_parent_folders("aws.hcl")
}

dependency "github-actions" {
  config_path = "../../github-actions"

  skip_outputs = true
}



inputs = {

}
