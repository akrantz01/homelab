{...}: {
  imports = [
    ./actualbudget
    ./atuin.nix
    ./authentication
    ./backblaze.nix
    ./continuous-deployment.nix
    ./database.nix
    ./mealie.nix
    ./miniflux.nix
    ./pvr.nix
    ./reverse-proxy.nix
    ./ssh-tunnel.nix
    ./streaming.nix
    ./torrent.nix
    ./vaultwarden.nix
    ./vpn.nix
  ];
}
