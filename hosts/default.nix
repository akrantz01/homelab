inputs@{ self, nixpkgs, ... }:

let
  system = "x86_64-linux";

  makeSystems = hostnames: nixpkgs.lib.attrsets.genAttrs hostnames (hostname: nixpkgs.lib.nixosSystem {
    inherit system;

    modules = [
      "${self}/hosts/${hostname}/configuration.nix"
      "${self}/common"
      "${self}/components"
      {
        _module.args = { inherit inputs hostname; };
      }
    ];
  });
in
makeSystems [ "krantz" ]
