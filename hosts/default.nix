inputs @ {
  self,
  nixpkgs,
  sops-nix,
  ...
}: let
  system = "x86_64-linux";

  makeSystems = hosts:
    builtins.listToAttrs (builtins.map
      (host: {
        name = host.hostname;
        value = nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            sops-nix.nixosModules.sops

            "${self}/hosts/${host.hostname}"
            "${self}/common"
            "${self}/components"
            "${self}/secrets"
            {
              _module.args = {inherit inputs host;};
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
          "2602:fb89:1:25::1/64"
          "fe80::aaa1:59ff:fec0:7e0c/64"
        ];

        routes = [
          "23.139.82.1"
          "2602:fb89:1::1"
        ];
      };
    }
  ]
