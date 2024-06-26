{
  description = "My homelab configuration";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, sops-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      flake.nixosConfigurations =
        let
          system = "x86_64-linux";

          specialArgs = { inherit self system; };
        in
        {
          krantz = nixpkgs.lib.nixosSystem {
            inherit specialArgs;

            modules = [
              "${self}/hosts/krantz/configuration.nix"
              "${self}/common"
              "${self}/components"
            ];
          };
        };

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bashInteractive
            copier
            just
            opentofu
            sops
            terragrunt
            tflint
            yamllint
          ];
          shellHook = ''
            alias j=just
          '';
        };
      };
    };

  nixConfig = {
    extra-substituters = [ "https://cache.garnix.io" ];
    extra-trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
  };
}
