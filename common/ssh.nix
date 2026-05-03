{
  host,
  lib,
  ...
}: let
  firstBoot = host.firstBoot or false;
in {
  services.openssh = {
    enable = firstBoot;

    settings = {
      PermitRootLogin = lib.mkForce "no";

      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;

      X11Forwarding = false;
    };
  };
}
