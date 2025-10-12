inputs @ {
  self,
  nixpkgs,
  nixpkgs-unstable,
  disko,
  sops-nix,
  tailfed,
  ...
}: let
  inherit (nixpkgs) lib;

  settings = import "${self}/settings";
  extra = import "${self}/extra" {inherit lib;};

  makeSystems = hosts:
    builtins.listToAttrs (builtins.map
      (host @ {system, ...}: let
        usesDisko = host.disko or false;

        pkgs-stable = import nixpkgs {inherit system;};
        pkgs-unstable = import nixpkgs-unstable {inherit system;};
      in {
        name = host.hostname;
        value = lib.nixosSystem {
          inherit system;

          modules =
            [
              sops-nix.nixosModules.sops
              tailfed.nixosModules.${system}.tailfed

              "${self}/hosts/${host.hostname}"
              "${self}/common"
              "${self}/components"
              "${self}/secrets"
              {
                _module.args = {inherit extra inputs host lib pkgs-stable pkgs-unstable self settings;};
              }
            ]
            ++ lib.lists.optional usesDisko disko.nixosModules.disko;
        };
      })
      hosts);
in (makeSystems [
  {
    hostname = "krantz";
    system = "x86_64-linux";
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
  {
    hostname = "idp";
    system = "x86_64-linux";
    disko = true;
    networking = {
      interface = "ens3";
      dhcp = true;
    };
  }
])
