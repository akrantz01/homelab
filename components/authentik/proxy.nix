{
  config,
  extra,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.authentik;
in {
  options.components.authentik.proxy = {
    enable = lib.mkEnableOption "Enable the authentik proxy component";
    token = extra.mkSecretOption "authentik proxy token" "authentik/proxy/token";
  };

  config = lib.mkIf cfg.proxy.enable {
    systemd.services.authentik-proxy = {
      description = "Authentik proxy outpost";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        AUTHENTIK_HOST = "https://${cfg.domain}";
        AUTHENTIK_TOKEN = "file://${config.sops.secrets."authentik/proxy/token".path}";
      };

      serviceConfig = {
        Type = "simple";
        User = "authentik-proxy";
        Group = "authentik-proxy";

        ExecStart = "${pkgs-unstable.authentik-outposts.proxy}/bin/proxy";

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
