{...}: {
  imports = [
    ./atuin.nix
    ./authentication
    ./backblaze.nix
    ./continuous-deployment.nix
    ./database.nix
    ./mealie.nix
    ./miniflux.nix
    ./reverse-proxy.nix
    ./ssh-tunnel.nix
    ./vaultwarden.nix
  ];
}
