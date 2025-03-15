{...}: {
  imports = [
    ./firewall.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./packages.nix
    ./ssh.nix
    ./tunnel.nix
    ./users.nix
  ];
}
