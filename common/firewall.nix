{...}: {
  # Enable the firewall.
  networking.firewall.enable = true;

  # Disable all ports by default.
  networking.firewall.allowedTCPPorts = [];
  networking.firewall.allowedUDPPorts = [];
}
