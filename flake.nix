{
  description = "My homelab configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # TODO: remove this once NixOS/nixpkgs#347825 is merged
    nixpkgs-actualbudget.url = "github:oddlama/nixpkgs/feat-actual-budget";
    # TODO: remove this once NixOS/nixpkgs#360592 is merged
    nixpkgs-sonarr.url = "github:NixOS/nixpkgs/4aa36568d413aca0ea84a1684d2d46f55dbabad7";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    nixosConfigurations = import ./hosts inputs;

    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        alejandra
        bashInteractive
        copier
        just
        nix-diff
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
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = ["cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="];
  };
}
