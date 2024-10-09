inputs @ {
  self,
  nixpkgs,
  nixpkgs-unstable,
  sops-nix,
  ...
}: let
  inherit (nixpkgs) lib;

  system = "x86_64-linux";
  settings = import "${self}/settings";
  extra = import "${self}/extra" {inherit lib;};

  pkgs-stable = import nixpkgs {inherit system;};
  pkgs-unstable = import nixpkgs-unstable {inherit system;};

  makeSystems = hosts:
    builtins.listToAttrs (builtins.map
      (host: {
        name = host.hostname;
        value = lib.nixosSystem {
          inherit system;

          modules = [
            sops-nix.nixosModules.sops

            "${self}/hosts/${host.hostname}"
            "${self}/common"
            "${self}/components"
            "${self}/secrets"
            {
              _module.args = {inherit extra inputs host lib pkgs-stable pkgs-unstable self settings;};
            }
          ];
        };
      })
      hosts);
in
  makeSystems [
    {
      hostname = "krantz";
      networking = {
        interface = "enp35s0";
        dhcp = false;

        addresses = [
          "23.139.82.37/24"
          "23.139.82.253/24"
          "2602:fb89:1:25::37:1/128"
          "2602:fb89:1:25::253:1/128"
          "fe80::aaa1:59ff:fec0:7e0c/64"
        ];

        routes = [
          "23.139.82.1"
          "2602:fb89:1::1"
        ];
      };
    }
  ]
