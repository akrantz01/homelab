inputs @ {
  self,
  nixpkgs,
  nixpkgs-unstable,
  nixpkgs-authentik,
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

        options = {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["n8n"];
        };
        pkgs-stable = import nixpkgs options;
        pkgs-unstable = import nixpkgs-unstable options;
        pkgs-authentik = import nixpkgs-authentik options;
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
                _module.args = {inherit extra inputs host lib pkgs-stable pkgs-unstable pkgs-authentik self settings;};
              }
            ]
            ++ lib.lists.optional usesDisko disko.nixosModules.disko;
        };
      })
      hosts);
in (makeSystems [
  {
    hostname = "primary";
    system = "x86_64-linux";
    disko = true;
    networking = {
      interface = "enp6s0";
      dhcp = "ipv4";

      addresses = [
        "51.79.11.112/24"
        "2607:5300:61:1039::57:1/128"
        "2607:5300:61:1039::112:1/128"
      ];
      routes = [
        "2607:5300:61:10ff:ff:ff:ff:ff"
      ];
    };
  }
  {
    hostname = "idp";
    system = "x86_64-linux";
    disko = true;
    networking = {
      interface = "ens3";
      dhcp = "ipv4";

      addresses = ["2607:5300:205:200::3f0e/128"];
      routes = ["2607:5300:205:200::1"];
    };
  }
  {
    hostname = "forge";
    system = "x86_64-linux";
    disko = true;
    firstBoot = true;
    networking = {
      interface = "ens3";
      dhcp = "ipv4";

      addresses = ["2607:5300:205:200::dfc/128"];
      routes = ["2607:5300:205:200::1"];
    };
  }
])
