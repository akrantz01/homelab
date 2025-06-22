include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "github-actions" {
  config_path = "../../github-actions"

  skip_outputs = true
}

inputs = {}
