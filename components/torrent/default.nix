{
  config,
  lib,
  pkgs-stable,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.torrent;

  concatPath = left: right: (lib.strings.removeSuffix "/" left) + "/" + (lib.strings.removePrefix "/" right);
in {
  options.components.torrent = {
    enable = lib.mkEnableOption "Enable the torrenting component";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "torrent.example.com";
      description = "The domain to use for the torrenting UI";
    };

    proxyAuth = lib.mkEnableOption "Enable proxy authentication";

    paths = {
      incomplete = lib.mkOption {
        type = with lib.types; nullOr str;
        description = "Where to store incomplete downloads";
        default = null;
      };
      complete = lib.mkOption {
        type = with lib.types; nullOr str;
        description = "Where to store complete downloads";
        default = null;
      };
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

    services.qbittorrent = {
      enable = true;
      package = pkgs-unstable.qbittorrent-nox;

      webuiPort = 7288;
      openFirewall = false;

      serverConfig = {
        LegalNotice.Accepted = true;

        Preferences = {
          General = {
            Locale = "en";
            StatusbarExternalIPDisplayed = true;
          };
          WebUI = {
            Address = "127.0.0.1";
            LocalHostAuth = !cfg.proxyAuth;
            ServerDomains = cfg.domain;
          };
        };

        Network.PortForwardingEnabled = false;

        Session = {
          GlobalMaxInactiveSeedingMinutes = 1800;
          GlobalMaxRatio = 1;
          ShareLimitAction = "Remove";

          DefaultSavePath =
            if cfg.paths.complete != null
            then cfg.paths.complete
            else (concatPath config.services.qbittorrent.profileDir "complete");
          TempPathEnabled = cfg.paths.incomplete != null;
          TempPath =
            if cfg.paths.incomplete != null
            then cfg.paths.incomplete
            else (concatPath config.services.qbittorrent.profileDir "complete");
        };
      };
    };

    systemd.services.qbittorrent = {
      bindsTo = ["vpn.service"];
      after = ["vpn.service"];
      unitConfig.JoinsNamespaceOf = "netns@vpn.service";
      serviceConfig = {
        BindReadOnlyPaths = "/etc/netns/vpn/resolv.conf:/etc/resolv.conf";
        PrivateNetwork = lib.mkForce true;
      };
    };

    systemd.sockets.qbittorrent-ui-proxy = {
      enable = true;
      wantedBy = ["sockets.target"];
      listenStreams = ["127.0.0.1:${toString config.services.qbittorrent.webuiPort}"];
    };
    systemd.services.qbittorrent-ui-proxy = {
      enable = true;
      description = "qBittorrent Web UI proxy";
      after = ["qbittorrent.service" "qbittorrent-ui-proxy.socket"];
      requires = ["qbittorrent.service"];

      unitConfig.JoinsNamespaceOf = "netns@vpn.service";
      serviceConfig = {
        Type = "notify";
        ExecStart = "${pkgs-stable.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${toString config.services.qbittorrent.webuiPort}";
        PrivateTmp = true;
        PrivateNetwork = true;
      };
    };

    systemd.timers.torrent-port-forward = {
      enable = true;
      description = "NAT-PMP/PCP port forwarding for torrenting";
      after = ["network.target" "qbittorrent-ui-proxy.service"];
      requires = ["qbittorrent-ui-proxy.service"];

      timerConfig = {
        OnBootSec = "45s";
        OnUnitActiveSec = "45s";

        AccuracySec = "1s";

        RandomizedDelaySec = 0;
        FixedRandomDelay = false;
      };

      wantedBy = ["timers.target"];
    };

    systemd.services.torrent-port-forward = {
      enable = true;
      after = ["network.target" "qbittorrent-ui-proxy.service" "vpn.service"];
      wants = ["qbittorrent-ui-proxy.service"];
      bindsTo = ["vpn.service"];

      unitConfig.JoinsNamespaceOf = "netns@vpn.service";

      path = [
        pkgs-unstable.libnatpmp
        pkgs-stable.curl
        pkgs-stable.gawk
      ];

      environment = {
        QBITTORRENT_API_PORT = toString config.services.qbittorrent.webuiPort;
      };

      serviceConfig = {
        Type = "oneshot";
        ExecStart = let src = ./forward-port.sh; in "${pkgs-stable.runtimeShell} ${src}";

        PrivateNetwork = true;
      };
    };

    components.reverseProxy.hosts.${cfg.domain}.locations."/" = {
      proxyTo = "http://127.0.0.1:${toString config.services.qbittorrent.webuiPort}";
      forwardAuth = cfg.proxyAuth;
    };
  };
}
