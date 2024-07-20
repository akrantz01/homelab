{ hostname, ... }:

{
  # Set the system hostname
  networking.hostName = hostname;

  # Uncomment to enable debug logging
  #systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";

  # Prefer systemd-networkd for networking for better reliability
  systemd.network.enable = true;
  networking = {
    useDHCP = false;
    networkmanager.enable = false;
  };
}
