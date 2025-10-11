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
        pkgs-stable = import nixpkgs {inherit system;};
        pkgs-unstable = import nixpkgs-unstable {inherit system;};
        pkgs-authentik = import nixpkgs-authentik {inherit system;};
      in {
        name = host.hostname;
        value = lib.nixosSystem {
          inherit system;

          modules = [
            sops-nix.nixosModules.sops
            tailfed.nixosModules.${system}.tailfed

            "${self}/hosts/${host.hostname}"
            "${self}/common"
            "${self}/components"
            "${self}/secrets"
            {
              _module.args = {inherit extra inputs host lib pkgs-stable pkgs-unstable pkgs-authentik self settings;};
            }
          ];
        };
      })
      hosts);
in
  (makeSystems [
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
      system = "aarch64-linux";
      networking = {
        interface = "ens5";
        dhcp = true;
      };
    }
  ])
  // {
    idp-2 = let
      system = "x86_64-linux";
      pkgs-stable = import nixpkgs {inherit system;};
      pkgs-unstable = import nixpkgs-unstable {inherit system;};
      host = {
        hostname = "idp";
        networking = {
          interface = "ens3";
          dhcp = true;
        };
      };
    in
      lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops

          "${self}/common/firewall.nix"
          "${self}/common/locale.nix"
          "${self}/common/networking.nix"
          "${self}/common/nix.nix"
          "${self}/common/packages.nix"
          "${self}/common/ssh.nix"
          "${self}/common/users.nix"
          "${self}/secrets"
          "${self}/hosts/idp/hardware-configuration.nix"
          "${self}/hosts/idp/disk-config.nix"
          {
            time.timeZone = "America/Montreal";

            services.openssh.openFirewall = lib.mkForce true;
            users.users.alex.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ+OPkkj+awp5kNpBYMuAfUtDOp4Fn3NbDg6wDD4yb/q alex@thinkpad-z13"];

            system.stateVersion = "25.05";
          }
          {
            _module.args = {inherit extra inputs host lib pkgs-stable pkgs-unstable self settings;};
          }
        ];
      };
  }
