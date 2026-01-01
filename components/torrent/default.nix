{
  config,
  lib,
  pkgs-stable,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.torrent;

  concatPath = left: right: (lib.strings.removeSuffix "/" left) + "/" + (lib.strings.removePrefix "/" right);

  daemonPort = 58846;

  deluge = config.services.deluge.package.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [
        ./disable-authentication.patch
      ];
  });
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
      serviceConfig.PrivateNetwork = lib.mkForce true;
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
          ${deluge}/bin/deluged \
            --do-not-daemonize \
            --config ${config.services.deluge.dataDir}/.config/deluge \
            --loglevel info
        '';
      };
    };

    systemd.services.delugeweb = {
      serviceConfig = {
        ExecStart = lib.mkForce ''
          ${deluge}/bin/deluge-web \
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

    systemd.timers.torrent-port-forward = {
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

    systemd.services.torrent-port-forward = {
      enable = true;
      after = ["network.target" "torrent-proxy.service" "vpn.service"];
      wants = ["torrent-proxy.service"];
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
