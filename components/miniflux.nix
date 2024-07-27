{
  config,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.miniflux;
in {
  options.components.miniflux = {
    enable = lib.mkEnableOption "Enable the Miniflux component";
    domain = lib.mkOption {
      type = lib.types.str;
      example = "reader.example.com";
      description = "The domain to use for the Miniflux instance";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.components.database.enable;
        message = "The database component must be enabled to use Vaultwarden";
      }
      {
        assertion = config.components.reverseProxy.enable;
        message = "The reverse proxy component must be enabled to use Vaultwarden";
      }
    ];

    services.miniflux = {
      enable = true;
      package = pkgs-unstable.miniflux;

      createDatabaseLocally = true;
      adminCredentialsFile = config.sops.templates."miniflux.env".path;

      config = {
        BASE_URL = "https://${cfg.domain}";
        HTTPS = 1;

        WEBAUTHN = 1;

        # No admin user here, we'll handle everything through OIDC
        CREATE_ADMIN = lib.mkForce 0;
      };
    };

    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;

      locations."/".proxyPass = "http://${config.services.miniflux.config.LISTEN_ADDR}";
    };

    sops.templates."miniflux.env" = {
      content = "";

      owner = config.systemd.services.miniflux.serviceConfig.User;
      group = config.systemd.services.miniflux.serviceConfig.User;
    };
  };
}
