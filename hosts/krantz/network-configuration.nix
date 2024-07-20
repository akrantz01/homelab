# Sets up the systems networking using systemd-networkd
# with static addresses and routes.

{ ... }:

let
  address = addr: { addressConfig.Address = addr; };
in
{
  # Set WAN routing configuration
  systemd.network.networks."10-wan" = {
    name = "enp35s0";

    # Ensure everything is static
    DHCP = "no";
    networkConfig = {
      IPv6AcceptRA = "no";
    };

    addresses = [
      (address "23.139.82.37/24")
      (address "23.139.82.253/24")
      (address "2602:fb89:1:25::1/64")
      (address "fe80::aaa1:59ff:fec0:7e0c/64")
    ];

    routes = [
      { routeConfig.Gateway = "23.139.82.1"; }
      { routeConfig = { Gateway = "2602:fb89:1::1"; GatewayOnLink = true; }; }
    ];

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
