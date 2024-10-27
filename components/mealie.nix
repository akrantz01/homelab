{
  lib,
  config,
  extra,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.mealie;

  database = "mealie";
in {
  options.components.mealie = {
    enable = lib.mkEnableOption "Enable the Mealie component";
    sopsFile = extra.mkSecretSourceOption config;

    domain = lib.mkOption {
      type = lib.types.str;
      default = "recipes.example.com";
      description = "The domain for the Mealie instance";
    };

    oidc = {
      enable = lib.mkEnableOption "Enable OIDC authentication for Mealie";

      configurationUrl = lib.mkOption {
        type = lib.types.str;
        description = "The OIDC configuration URL";
      };

      clientId = lib.mkOption {
        type = lib.types.str;
        description = "The OIDC PKCE client ID";
      };

      provider = lib.mkOption {
        type = lib.types.str;
        default = "OAuth";
        description = "Name of the OIDC provider";
      };

      groups = {
        user = lib.mkOption {
          type = lib.types.str;
          default = "Recipes";
          description = "The user group";
        };

        admin = lib.mkOption {
          type = lib.types.str;
          default = "Sysadmins";
          description = "The admin group";
        };
      };
    };

    openai = {
      enable = lib.mkEnableOption "Enable OpenAI integration";
      apiKey = extra.mkSecretOption "OpenAI api key" "mealie/openai_token";
      model = lib.mkOption {
        type = lib.types.str;
        default = "gpt-4o";
        description = "The OpenAI model to use";
      };
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

      listenAddress = "[::1]";
      port = 6325;

      settings = lib.attrsets.mergeAttrsList [
        {
          DB_ENGINE = "postgres";
          POSTGRES_URL_OVERRIDE = "postgresql://:@mealie?host=/run/postgresql";

          DEFAULT_GROUP = "Home";

          BASE_URL = "https://${cfg.domain}";

          TZ = "America/Vancouver";

          ALLOW_SIGNUP = "false";

          SECURITY_MAX_LOGIN_ATTEMPTS = "3";
          SECURITY_USER_LOCKOUT_TIME = "24";
        }
        (lib.optionalAttrs cfg.oidc.enable
          {
            OIDC_AUTH_ENABLED = true;
            OIDC_SIGNUP_ENABLED = true;
            OIDC_AUTO_REDIRECT = true;

            OIDC_CONFIGURATION_URL = cfg.oidc.configurationUrl;
            OIDC_CLIENT_ID = cfg.oidc.clientId;
            OIDC_PROVIDER_NAME = cfg.oidc.provider;

            OIDC_USER_GROUP = cfg.oidc.groups.user;
            OIDC_ADMIN_GROUP = cfg.oidc.groups.admin;
          })
        (lib.optionalAttrs cfg.openai.enable
          {
            # TODO: figure out how to set OPENAI_API_KEY
            OPENAI_MODEL = cfg.openai.model;
          })
      ];
    };

    systemd.services.mealie.environment.ALEMBIC_CONFIG_FILE = lib.mkForce "${pkgs-unstable.mealie}/alembic.ini";

    sops.secrets."mealie/openai_token" = {
      key = cfg.openai.apiKey;
      sopsFile = cfg.sopsFile;

      owner = config.systemd.services.mealie.serviceConfig.User;
      group = config.systemd.services.mealie.serviceConfig.User;

      restartUnits = [config.systemd.services.mealie.name];
    };

    components.reverseProxy.hosts.${cfg.domain}.locations."/" = {
      proxyTo = let
        mealie = config.services.mealie;
        host = mealie.listenAddress;
        port = builtins.toString mealie.port;
      in "http://${host}:${port}";

      proxyWebsockets = true;
    };
  };
}
