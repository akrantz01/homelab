{
  config,
  extra,
  lib,
  pkgs-stable,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.torrent;
in {
  options.components.torrent = {
    enable = lib.mkEnableOption "Enable the torrenting component";
    sopsFile = extra.mkSecretSourceOption config;

    domain = lib.mkOption {
      type = lib.types.str;
      example = "torrent.example.com";
      description = "The domain to use for the torrenting UI";
    };

    publicAddress = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The public address to advertise to peers";
    };

    rpc = {
      username = extra.mkSecretOption "The username for the Transmission RPC socket" "transmission/rpc/username";
      password = extra.mkSecretOption "The password for the Transmission RPC socket" "transmission/rpc/password";
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

    # services.transmission = {
    #   enable = true;
    #   package = pkgs-unstable.transmission_4;

    #   downloadDirPermissions = "760";

    #   settings = {
    #     rpc-bind-address = "unix:/run/transmission/rpc.sock";

    #     download-dir = "${config.services.transmission.home}/complete";

    #     incomplete-dir-enabled = true;
    #     incomplete-dir = "${config.services.transmission.home}/incomplete";

    #     port-forwarding-enabled = false;

    #     message-level = 5;

    #     announce-ip-enabled = cfg.publicAddress != null;
    #     announce-ip =
    #       if cfg.publicAddress != null
    #       then cfg.publicAddress
    #       else "";
    #   };
    #   credentialsFile = config.sops.templates."transmission/credentials.json".path;
    # };

    systemd.services.deluged = {
      bindsTo = ["vpn.service"];
      after = ["vpn.service"];
      unitConfig.JoinsNamespaceOf = "netns@vpn.service";
      serviceConfig.PrivateNetwork = true;
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

    # systemd.sockets.torrent-proxy = {
    #   enable = true;
    #   wantedBy = ["sockets.target"];
    #   listenStreams = ["127.0.0.1:${config.services.deluge.web.port}"];
    # };
    # systemd.services.torrent-proxy = {
    #   enable = true;
    #   description = "Torrent API proxy";
    #   after = ["deluged.service" "torrent-proxy.socket"];
    #   requires = ["deluged.service"];

    #   unitConfig.JoinsNamespaceOf = "netns@vpn.service";
    #   serviceConfig = {
    #     Type = "notify";

    #     ExecStart = "${pkgs-stable.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${config.services.deluge.web.port}";

    #     PrivateTmp = true;
    #     PrivateNetwork = true;
    #   };
    # };

    systemd.timers.natpmp = {
      enable = true;
      description = "NAT-PMP/PCP port forwarding for Transmission";
      after = ["network.target" "transmission-proxy.service"];
      requires = ["transmission-proxy.service"];

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
      after = ["network.target" "transmission-proxy.service" "vpn.service"];
      wants = ["transmission-proxy.service"];
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

    sops.secrets = let
      secret = key: {
        inherit key;
        inherit (cfg) sopsFile;

        owner = config.services.deluge.user;
        group = config.services.deluge.group;

        reloadUnits = [config.systemd.services.deluged.name];
      };
    in {
      "transmission/rpc/username" = secret cfg.rpc.username;
      "transmission/rpc/password" = secret cfg.rpc.password;
    };

    sops.templates."transmission/credentials.json" = {
      content = builtins.toJSON {
        rpc-username = config.sops.placeholder."transmission/rpc/username";
        rpc-password = config.sops.placeholder."transmission/rpc/password";
      };

      owner = config.services.deluge.user;
      group = config.services.deluge.group;
    };
  };
}
