{
  config,
  lib,
  pkgs-stable,
  ...
}: let
  githubSshKeys = username: hash: let
    keysSource = pkgs-stable.fetchurl {
      inherit hash;
      url = "https://github.com/${username}.keys";
    };
    allKeys = lib.splitString "\n" (builtins.readFile keysSource);
  in
    builtins.filter (key: (builtins.stringLength key) > 0) allKeys;
in {
  # Users must be managed through NixOS
  users.mutableUsers = false;

  # Define the default user account
  users.users.alex = {
    isNormalUser = true;
    description = "Alex Krantz";
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = githubSshKeys "akrantz01" "sha256-Ziu5Kn8Vg5u1bWcCtySa6eXCFgMzlupQskzzjxn2PQc=";
    hashedPasswordFile = config.sops.secrets."users/alex".path;
  };

  # Secrets containing hashed user passwords
  sops.secrets."users/alex".neededForUsers = true;

  # Allow passwordless sudo
  security.sudo.wheelNeedsPassword = false;
}
