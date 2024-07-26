{
  lib,
  config,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.mealie;

  database = "mealie";
in {
  options.components.mealie = {
    enable = lib.mkEnableOption "Enable the Mealie component";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "recipes.example.com";
      description = "The domain for the Mealie instance";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.components.database.enable;
        message = "The database component must be enabled to use Mealie";
      }
    ];

    components.database.databases = [database];

    services.mealie = {
      enable = true;
      package = pkgs-unstable.mealie;

      listenAddress = "::1";
      port = 6325;

      settings = {
        DB_ENGINE = "postgres";
        POSTGRES_URL_OVERRIDE = "postgresql://mealie?host=/run/postgresql";

        DEFAULT_GROUP = "Home";

        BASE_URL = "https://${cfg.domain}";

        TZ = "America/Vancouver";

        ALLOW_SIGNUP = "false";

        SECURITY_MAX_LOGIN_ATTEMPTS = "3";
        SECURITY_USER_LOCKOUT_TIME = "24";
      };
    };

    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;

      locations."/" = {
        proxyPass = "http://[${config.services.mealie.listenAddress}]:${builtins.toString config.services.mealie.port}";
        proxyWebsockets = true;
      };
    };
  };
}
