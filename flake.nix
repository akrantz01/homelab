{
  description = "My homelab configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations.krantz = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          "${self}/hosts/krantz/configuration.nix"
          "${self}/common"
          # "${self}/components"
          {
            _module.args = { inherit inputs; };
          }
        ];
      };

      devShells.${system}.default = pkgs.mkShell {
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

  nixConfig = {
    extra-substituters = [ "https://cache.garnix.io" ];
    extra-trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
  };
}
