{
  description = "My homelab configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

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
      packages =
        (with pkgs; [
          alejandra
          bashInteractive
          copier
          just
          nix-diff
          sops
          terragrunt
          tflint
          yamllint
        ])
        ++ [pkgs-unstable.opentofu];

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
