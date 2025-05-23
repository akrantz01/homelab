{
  config,
  extra,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.authentik;
in {
  options.components.authentik.ldap = {
    enable = lib.mkEnableOption "Enable the authentik LDAP component";
    token = extra.mkSecretOption "authentik LDAP token" "authentik/ldap/token";

    listeners = {
      ldap = lib.mkOption {
        type = lib.types.str;
        default = "[::1]:2889";
        description = "The address to listen on for LDAP connections";
      };
      ldaps = lib.mkOption {
        type = lib.types.str;
        default = "[::1]:2836";
        description = "The address to listen on for LDAPS connections";
      };
      metrics = lib.mkOption {
        type = lib.types.str;
        default = "[::1]:2840";
        description = "The address the metrics server should listen on";
      };
    };
  };

  config = lib.mkIf cfg.ldap.enable {
    systemd.services.authentik-ldap = {
      description = "Authentik LDAP outpost";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        AUTHENTIK_HOST = "https://${cfg.domain}";
        AUTHENTIK_TOKEN = "file://${config.sops.secrets."authentik/ldap/token".path}";

        AUTHENTIK_LISTEN__LDAP = cfg.ldap.listeners.ldap;
        AUTHENTIK_LISTEN__LDAPS = cfg.ldap.listeners.ldaps;
        AUTHENTIK_LISTEN__METRICS = cfg.ldap.listeners.metrics;
      };

      serviceConfig = {
        Type = "simple";
        User = "authentik-ldap";
        Group = "authentik-ldap";

        ExecStart = "${pkgs-unstable.authentik-outposts.ldap}/bin/ldap";

        Restart = "on-failure";
        RestartSec = 5;

        RuntimeDirectory = "authentik-ldap";
      };

      unitConfig = {
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
    };

    users = {
      users.authentik-ldap = {
        isSystemUser = true;
        group = config.users.groups.authentik-ldap.name;
      };
      groups.authentik-ldap = {};
    };

    sops.secrets."authentik/ldap/token" = {
      key = cfg.ldap.token;
      inherit (cfg) sopsFile;

      owner = config.users.users.authentik-ldap.name;
      group = config.users.users.authentik-ldap.group;

      restartUnits = [config.systemd.services.authentik-ldap.name];
    };
  };
}
