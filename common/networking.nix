{
  host,
  lib,
  ...
}: {
  # Set the system hostname
  networking.hostName = host.hostname;

  # Uncomment to enable debug logging
  #systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";

  # Prefer systemd-networkd for networking for better reliability
  systemd.network.enable = true;
  networking = {
    useDHCP = false;
    networkmanager.enable = false;
  };

  # System resolver security
  services.resolved.llmnr = "false";
  services.resolved.dnssec = "true";

  # Configure the WAN interface
  systemd.network.networks."10-wan" = let
    dhcp =
      if host.networking.dhcp
      then "yes"
      else "no";
  in {
    name = host.networking.interface;

    DHCP = dhcp;
    networkConfig.IPv6AcceptRA = dhcp;

    addresses = lib.mkIf (!host.networking.dhcp) (builtins.map (addr: {addressConfig.Address = addr;}) host.networking.addresses);
    routes = lib.mkIf (!host.networking.dhcp) (builtins.map
      (route: {
        routeConfig = {
          Gateway = route;
          GatewayOnLink = lib.mkIf (lib.strings.hasInfix ":" route) true;
        };
      })
      host.networking.routes);

    dns = [
      "1.1.1.1"
      "2606:4700:4700::1111"
      "1.0.0.1"
      "2606:4700:4700::1001"
    ];

    # Make the routes on this interface a dependency for network-online.target.
    linkConfig.RequiredForOnline = "routable";
  };
}
