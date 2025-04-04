include "root" {
  path = find_in_parent_folders()
}

dependency "github-actions" {
  config_path = "../../github-actions"

  skip_outputs = true
}

inputs = {
  repositories = {
    initializer = "an API gateway handler for starting a device verification flow."
    verifier    = "a step function component responsible for verifying the challenge given by the initializer Lambda."
    finalizer   = "an API gateway handler for issuing the token once a device has been successfully verified."
  }
}
