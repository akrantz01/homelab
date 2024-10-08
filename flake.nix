{
  description = "My homelab configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pin to chromium 126 for now until https://github.com/FlareSolverr/FlareSolverr/issues/1318 is resolved
    nixpkgs-chromium.url = "github:NixOS/nixpkgs/10c6033249917048251e2812c64b63d6588aa34b";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
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
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = ["cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="];
  };
}
