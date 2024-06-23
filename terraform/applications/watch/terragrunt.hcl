include "root" {
  path = find_in_parent_folders()
}

include "b2" {
  path = find_in_parent_folders("b2.hcl")
}

dependency "github-actions" {
  config_path = "../../github-actions"

  skip_outputs = true
}



inputs = {

}
