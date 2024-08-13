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
    ];

    services.transmission = {
      enable = true;
      package = pkgs-unstable.transmission_4;

      downloadDirPermissions = "760";

      settings = {
        rpc-bind-address = "unix:/run/transmission/rpc.sock";

        download-dir = "${config.services.transmission.home}/complete";

        incomplete-dir-enabled = true;
        incomplete-dir = "${config.services.transmission.home}/incomplete";
      };
      credentialsFile = config.sops.templates."transmission/credentials.json".path;
    };

    systemd.services.transmission = {
      bindsTo = ["vpn.service"];
      after = ["vpn.service"];
      unitConfig.JoinsNamespaceOf = "netns@vpn.service";
      serviceConfig.PrivateNetwork = true;
    };

    systemd.sockets.transmission-proxy = {
      enable = true;
      wantedBy = ["sockets.target"];
      listenStreams = ["8767"];
    };
    systemd.services.transmission-proxy = {
      enable = true;
      description = "Transmission RPC proxy";
      after = ["transmission.service" "transmission-proxy.socket"];
      requires = ["transmission.service"];

      unitConfig.JoinsNamespaceOf = "netns@vpn.service";
      serviceConfig = {
        Type = "notify";

        ExecStart = "${pkgs-stable.systemd}/lib/systemd/systemd-socket-proxyd /run/transmission/rpc.sock";

        PrivateTmp = true;
        PrivateNetwork = true;
      };
    };

    systemd.services.flood = {
      enable = true;
      description = "Flood web UI for Transmission";
      after = ["netowrk.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";

        ExecStart = pkgs-stable.writers.writeBash "exec-start-flood" ''
          exec ${pkgs-unstable.flood}/bin/flood \
            --rundir=/var/lib/flood \
            --auth=none \
            --host=127.0.0.1 \
            --port=3563 \
            --allowedpath=${config.services.transmission.settings.download-dir} \
            --allowedpath=${config.services.transmission.settings.incomplete-dir} \
            --trurl=http://127.0.0.1:8767 \
            --truser="$(cat ${config.sops.secrets."transmission/rpc/username".path})" \
            --trpass="$(cat ${config.sops.secrets."transmission/rpc/password".path})"
        '';

        User = config.services.transmission.user;
        Group = config.services.transmission.group;

        Restart = "on-failure";
        RestartSec = 3;

        StateDirectory = "flood";
      };
    };

    sops.secrets = let
      secret = key: {
        inherit key;
        inherit (cfg) sopsFile;

        owner = config.services.transmission.user;
        group = config.services.transmission.group;

        reloadUnits = [config.systemd.services.transmission.name];
        restartUnits = [config.systemd.services.flood.name];
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

      owner = config.services.transmission.user;
      group = config.services.transmission.group;
    };
  };
}
