{...}: {
  imports = [
    ./atuin.nix
    ./authentik
    ./aws.nix
    ./backblaze.nix
    ./continuous-deployment.nix
    ./database.nix
    ./mealie
    ./meilisearch.nix
    ./miniflux.nix
    ./pvr.nix
    ./reverse-proxy.nix
    ./streaming.nix
    ./torrent
    ./vaultwarden.nix
    ./vpn.nix
    ./workflows
  ];
}
