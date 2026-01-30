{
  description = "My homelab configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # TODO: remove once PR merged and nixos-unstable updated
    # https://github.com/NixOS/nixpkgs/pull/485210
    nixpkgs-authentik.url = "github:akrantz01/nixpkgs/authentik/2025.12.1-validation";

    disko = {
      url = "github:nix-community/disko/v1.13.0";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere/1.13.0";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
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
    disko,
    nixpkgs,
    nixpkgs-unstable,
    nixos-anywhere,
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
        disko.packages.${system}.default
        just
        opentofu
        nix-diff
        nixos-anywhere.packages.${system}.default
        nixos-rebuild
        ssh-to-age
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
