data "github_release" "applier" {
  owner      = "akrantz01"
  repository = "applier"

  retrieve_by = "latest"
}

locals {
  # Select the correct asset based on its extension
  applier_downloads = {
    systemd_service = [for asset in data.github_release.applier.assets : asset.browser_download_url if endswith(asset.name, ".service")][0]
    systemd_socket  = [for asset in data.github_release.applier.assets : asset.browser_download_url if endswith(asset.name, ".socket")][0]
  }
}
