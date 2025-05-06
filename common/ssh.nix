{lib, ...}: {
  services.openssh = {
    enable = true;
    openFirewall = false;

    settings = {
      PermitRootLogin = lib.mkForce "no";

      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;

      X11Forwarding = false;
    };
  };
}
