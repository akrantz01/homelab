{...}: {
  imports = [
    ./atuin.nix
    ./continuous-deployment.nix
    ./database.nix
    ./mealie.nix
    ./reverse-proxy.nix
    ./vaultwarden.nix
  ];
}
