{ ... }:

{
  # Users must be managed through NixOS
  users.mutableUsers = false;

  # Define the default user account
  users.users.alex = {
    isNormalUser = true;
    description = "Alex Krantz";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ+OPkkj+awp5kNpBYMuAfUtDOp4Fn3NbDg6wDD4yb/q alex@thinkpad-z13" ];
  };

  # Allow passwordless sudo
  security.sudo.wheelNeedsPassword = false;
}
