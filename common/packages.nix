{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim # we need an editor

    git # for nix flakes
  ];

  environment.variables.EDITOR = "vim";
}
