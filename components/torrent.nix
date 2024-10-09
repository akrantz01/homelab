{
  config,
  lib,
  pkgs-stable,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.torrent;

  daemonPort = 58846;
in {
  options.components.torrent = {
    enable = lib.mkEnableOption "Enable the torrenting component";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "torrent.example.com";
      description = "The domain to use for the torrenting UI";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.components.vpn.enable;
        message = "The VPN component must be enabled to use the torrenting component";
      }
      {
        assertion = config.components.reverseProxy.enable;
        message = "The reverse proxy component must be enabled to use the torrenting component";
      }
    ];

    services.deluge = {
      enable = true;
      package = pkgs-unstable.deluge-2_x;

      openFirewall = false;

      web = {
        enable = true;
        openFirewall = false;
      };
    };

    systemd.services.deluged = {
      bindsTo = ["vpn.service"];
      after = ["vpn.service"];
      unitConfig.JoinsNamespaceOf = "netns@vpn.service";
      serviceConfig = {
        PrivateNetwork = true;

        ExecStart = lib.mkForce ''
          ${config.services.deluge.package}/bin/deluged \
            --do-not-daemonize \
            --config ${config.services.deluge.dataDir}/.config/deluge \
            --loglevel info
        '';
      };
    };

    systemd.services.delugeweb = {
      serviceConfig = {
        ExecStart = lib.mkForce ''
          ${config.services.deluge.package}/bin/deluge-web \
            --do-not-daemonize \
            --config ${config.services.deluge.dataDir}/.config/deluge \
            --port ${toString config.services.deluge.web.port} \
            --interface 127.0.0.1
        '';
      };
    };

    systemd.sockets.torrent-proxy = {
      enable = true;
      wantedBy = ["sockets.target"];
      listenStreams = ["127.0.0.1:${toString daemonPort}"];
    };
    systemd.services.torrent-proxy = {
      enable = true;
      description = "Torrent API proxy";
      after = ["deluged.service" "torrent-proxy.socket"];
      requires = ["deluged.service"];

      unitConfig.JoinsNamespaceOf = "netns@vpn.service";
      serviceConfig = {
        Type = "notify";

        ExecStart = "${pkgs-stable.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${toString daemonPort}";

        PrivateTmp = true;
        PrivateNetwork = true;
      };
    };

    systemd.timers.natpmp = {
      enable = true;
      description = "NAT-PMP/PCP port forwarding for torrenting";
      after = ["network.target" "torrent-proxy.service"];
      requires = ["torrent-proxy.service"];

      timerConfig = {
        OnBootSec = "45s";
        OnUnitActiveSec = "45s";

        AccuracySec = "1s";

        RandomizedDelaySec = 0;
        FixedRandomDelay = false;
      };

      wantedBy = ["timers.target"];
    };

    systemd.services.natpmp = {
      enable = true;
      after = ["network.target" "torrent-proxy.service" "vpn.service"];
      wants = ["torrent-proxy.service"];
      bindsTo = ["vpn.service"];

      unitConfig.JoinsNamespaceOf = "netns@vpn.service";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = [
          "${pkgs-unstable.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 1 0 udp"
          "${pkgs-unstable.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 1 0 tcp"
        ];

        PrivateNetwork = true;
      };
    };

    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;

      locations."/".proxyPass = "http://127.0.0.1:${toString config.services.deluge.web.port}";
    };
  };
}
