include "root" {
  path = find_in_parent_folders("root.hcl")
}

exclude {
  if      = true
  actions = ["all_except_output"]
}
