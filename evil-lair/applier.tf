data "github_release" "applier" {
  owner      = "akrantz01"
  repository = "applier"

  retrieve_by = "latest"
}

locals {
  # Find the systemd units based on their extensions
  applier_downloads = [for asset in data.github_release.applier.assets : asset if endswith(asset.name, ".service") || endswith(asset.name, ".socket")]
}
