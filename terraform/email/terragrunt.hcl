include "root" {
  path = find_in_parent_folders()
}

include "aws" {
  path = find_in_parent_folders("aws.hcl")
}

include "cloudflare" {
  path = find_in_parent_folders("cloudflare.hcl")
}