{
  config,
  host,
  lib,
  ...
}: let
  firstBoot = host.firstBoot or false;
  opensshKeysFor = username: hash:
    builtins.fetchurl {
      url = "https://github.com/${username}.keys";
      sha256 = hash;
    };
in {
  # Users must be managed through NixOS
  users.mutableUsers = false;

  # Define the default user account
  users.users.alex = {
    isNormalUser = true;
    description = "Alex Krantz";
    extraGroups = ["wheel"];
    hashedPasswordFile = config.sops.secrets."users/alex".path;
    openssh.authorizedKeys.keyFiles = lib.lists.optional firstBoot (opensshKeysFor "akrantz01" "sha256:1z3qlwv3m5rczvivn1yhihdafqqrs04m0180rfq47v0x1n3yy9xn");
  };

  # Secrets containing hashed user passwords
  sops.secrets."users/alex".neededForUsers = true;

  # Allow passwordless sudo
  security.sudo.wheelNeedsPassword = false;
}
