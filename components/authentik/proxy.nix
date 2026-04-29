{
  config,
  extra,
  lib,
  pkgs-authentik,
  ...
}: let
  cfg = config.components.authentik;
in {
  options.components.authentik.proxy = {
    enable = lib.mkEnableOption "Enable the authentik proxy component";
    token = extra.mkSecretOption "authentik proxy token" "authentik/proxy/token";

    listeners = {
      http = lib.mkOption {
        type = lib.types.str;
        default = "[::1]:2880";
        description = "The address to listen on for HTTP connections";
      };
      https = lib.mkOption {
        type = lib.types.str;
        default = "[::1]:2843";
        description = "The address to listen on for HTTPS connections";
      };
      metrics = lib.mkOption {
        type = lib.types.str;
        default = "[::1]:2830";
        description = "The address the metrics server should listen on";
      };
    };
  };

  config = lib.mkIf cfg.proxy.enable {
    systemd.services.authentik-proxy = {
      description = "Authentik proxy outpost";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        AUTHENTIK_HOST = "https://${cfg.domain}";
        AUTHENTIK_TOKEN = "file://${config.sops.secrets."authentik/proxy/token".path}";

        AUTHENTIK_LISTEN__HTTP = cfg.proxy.listeners.http;
        AUTHENTIK_LISTEN__HTTPS = cfg.proxy.listeners.https;
        AUTHENTIK_LISTEN__METRICS = cfg.proxy.listeners.metrics;
      };

      serviceConfig = {
        Type = "simple";
        User = "authentik-proxy";
        Group = "authentik-proxy";

        ExecStart = "${pkgs-authentik.authentik-outposts.proxy}/bin/proxy";

        Restart = "on-failure";
        RestartSec = 5;

        RuntimeDirectory = "authentik-proxy";
      };

      unitConfig = {
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
    };

    users = {
      users.authentik-proxy = {
        isSystemUser = true;
        group = config.users.groups.authentik-proxy.name;
      };
      groups.authentik-proxy = {};
    };

    sops.secrets."authentik/proxy/token" = {
      key = cfg.proxy.token;
      inherit (cfg) sopsFile;

      owner = config.users.users.authentik-proxy.name;
      group = config.users.groups.authentik-proxy.name;

      restartUnits = [config.systemd.services.authentik-proxy.name];
    };
  };
}
