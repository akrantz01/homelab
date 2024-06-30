{ self, lib, ... }:

let
  base = "${self}/common";
  files = lib.attrsets.mapAttrsToList (path: _: "${base}/${path}") (builtins.readDir base);
  importable = builtins.filter (path: !lib.strings.hasSuffix "default.nix" path) files;
in
{
  imports = importable;
}
