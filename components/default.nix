{...}: {
  imports = [
    ./atuin.nix
    ./continuous-deployment.nix
    ./database.nix
    ./reverse-proxy.nix
    ./vaultwarden.nix
  ];
}
