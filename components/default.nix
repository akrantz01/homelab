{...}: {
  imports = [
    ./atuin.nix
    ./continuous-deployment.nix
    ./database.nix
    ./mealie.nix
    ./miniflux.nix
    ./reverse-proxy.nix
    ./vaultwarden.nix
  ];
}
