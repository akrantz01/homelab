{ ... }:

{
  imports = [
    ./firewall.nix
    ./locale.nix
    ./nix.nix
    ./packages.nix
    ./ssh.nix
    ./users.nix
  ];
}
