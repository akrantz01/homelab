include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "b2" {
  path = find_in_parent_folders("providers/b2.hcl")
}
