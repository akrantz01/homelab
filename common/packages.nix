{ pkgs }:

{
  environment.systemPackages = with pkgs; [
    vim # we need an editor

    git # for nix flakes
  ];
}
