{...}: {
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.openssh.settings = {
    PermitRootLogin = "no";

    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;

    X11Forwarding = false;
  };
}
