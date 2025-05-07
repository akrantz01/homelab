{config, ...}: {
  # Users must be managed through NixOS
  users.mutableUsers = false;

  # Define the default user account
  users.users.alex = {
    isNormalUser = true;
    description = "Alex Krantz";
    extraGroups = ["wheel"];
    hashedPasswordFile = config.sops.secrets."users/alex".path;
  };

  # Secrets containing hashed user passwords
  sops.secrets."users/alex".neededForUsers = true;

  # Allow passwordless sudo
  security.sudo.wheelNeedsPassword = false;
}
