{
  description = "My homelab configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # TODO: remove once https://github.com/mealie-recipes/mealie/pull/5184 is merged
    nixpkgs-mealie.url = "github:NixOS/nixpkgs/e6031a08f659a178d0e4dcb9f3c8d065a0e6da4d";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    tailfed = {
      url = "github:akrantz01/tailfed/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    pkgs-unstable = import nixpkgs-unstable {inherit system;};
  in {
    nixosConfigurations = import ./hosts inputs;

    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs-unstable; [
        alejandra
        bashInteractive
        copier
        just
        opentofu
        nix-diff
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
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = ["cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="];
  };
}
