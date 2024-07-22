{...}: {
  # Enable the firewall using nftables
  networking.firewall.enable = true;
  networking.nftables.enable = true;

  # Disable all ports by default.
  networking.firewall.allowedTCPPorts = [80 443];
  networking.firewall.allowedUDPPorts = [];
}
