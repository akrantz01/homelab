{...}: {
  imports = [
    ./actualbudget
    ./atuin.nix
    ./authentication
    ./backblaze.nix
    ./continuous-deployment.nix
    ./database.nix
    ./mealie
    ./miniflux.nix
    ./pvr.nix
    ./reverse-proxy.nix
    ./streaming.nix
    ./torrent.nix
    ./vaultwarden.nix
    ./vpn.nix
  ];
}
