{
  host,
  pkgs-stable,
  ...
}: {
  assertions = [
    {
      assertion = host.networking.dhcp == "yes" || host.networking.dhcp == "ipv4" || host.networking.dhcp == "ipv6" || host.networking.dhcp == "no";
      message = "networking.dhcp must be one of: yes, ipv4, ipv6, no";
    }
  ];

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
  services.resolved.dnssec = "false";
  # "opportunistic": try DoT first, fall back to plaintext if the TLS
  # connection fails. "enforce" would prevent any plaintext fallback but
  # risks total DNS failure if Cloudflare's DoT endpoint is unreachable.
  services.resolved.dnsovertls = "opportunistic";
  # Lock fallback resolvers to Cloudflare only; the compiled-in systemd
  # defaults include Google and Quad9 which we don't want.
  services.resolved.fallbackDns = [
    "1.1.1.1#cloudflare-dns.com"
    "2606:4700:4700::1111#cloudflare-dns.com"
    "1.0.0.1#cloudflare-dns.com"
    "2606:4700:4700::1001#cloudflare-dns.com"
  ];

  # Configure the WAN interface
  systemd.network.networks."10-wan" = {
    name = host.networking.interface;

    DHCP = host.networking.dhcp;
    networkConfig.IPv6AcceptRA =
      if host.networking ? ipv6AcceptRa
      then host.networking.ipv6AcceptRa
      else (host.networking.dhcp == "yes" || host.networking.dhcp == "ipv6");

    addresses = builtins.map (addr: {Address = addr;}) (host.networking.addresses or []);
    routes =
      builtins.map
      (route: {
        Gateway = route;
        GatewayOnLink = true;
      })
      (host.networking.routes or []);

    dns = [
      "1.1.1.1#cloudflare-dns.com"
      "2606:4700:4700::1111#cloudflare-dns.com"
      "1.0.0.1#cloudflare-dns.com"
      "2606:4700:4700::1001#cloudflare-dns.com"
    ];

    # Prevent DHCP-provided DNS servers and search domains from being passed to
    # systemd-resolved. Without this, DHCP (e.g. OVH) pushes its own resolvers
    # into the pool where they can become the active server on Cloudflare failures.
    dhcpV4Config = {
      UseDNS = false;
      UseDomains = false;
    };
    dhcpV6Config = {
      UseDNS = false;
      UseDomains = false;
    };

    # Make the routes on this interface a dependency for network-online.target.
    linkConfig.RequiredForOnline = "routable";
  };

  systemd.services."netns@" = {
    description = "%I network namespace";
    before = ["network.target"];

    path = with pkgs-stable; [iproute2 util-linux];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      PrivateNetwork = true;
      PrivateMounts = false;

      ExecStart = let
        script = pkgs-stable.writers.writeBash "netns-up" ''
          ip netns add $1
          umount /var/run/netns/$1
          mount --bind /proc/self/ns/net /var/run/netns/$1
        '';
      in "${script} %I";
      ExecStop = "ip netns del %I";
    };
  };
}
