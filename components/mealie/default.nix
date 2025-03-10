{
  lib,
  config,
  extra,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.mealie;

  secretsDir = "/var/lib/mealie/secrets";
  database = "mealie";

  mkSecret = key: name: {
    inherit key;
    sopsFile = cfg.sopsFile;

    path = "${secretsDir}/${name}";
    owner = config.systemd.services.mealie.serviceConfig.User;
    group = config.systemd.services.mealie.serviceConfig.User;

    restartUnits = [config.systemd.services.mealie.name];
  };

  mealie = pkgs-unstable.mealie.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [
        ./custom-secrets-dir.patch
      ];
  });
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
        description = "The OIDC client ID";
      };

      clientSecret = extra.mkSecretOption "The OIDC client secret" "mealie/oidc_client_secret";

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
      apiKey = extra.mkSecretOption "OpenAI api key" "mealie/openai_api_key";
      model = lib.mkOption {
        type = lib.types.str;
        default = "gpt-4o";
        description = "The OpenAI model to use";
      };
    };

    smtp = {
      enable = lib.mkEnableOption "Enable SMTP for sending emails";

      host = extra.mkSecretOption "SMTP host" "mealie/smtp/host";
      port = extra.mkSecretOption "SMTP port" "mealie/smtp/port";
      username = extra.mkSecretOption "SMTP username" "mealie/smtp/username";
      password = extra.mkSecretOption "SMTP password" "mealie/smtp/password";

      security = lib.mkOption {
        type = lib.types.str;
        default = "TLS";
        description = "The security method to use for the SMTP connection (TLS, SSL, NONE)";
      };

      from = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Recipes";
          description = "The name to use for the from field in emails";
        };
        address = lib.mkOption {
          type = lib.types.str;
          default = "no-reply@${cfg.domain}";
          description = "The email to use for the from field in emails";
        };
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
      package = mealie;

      listenAddress = "[::1]";
      port = 6325;

      settings = lib.attrsets.mergeAttrsList [
        {
          SECRETS_DIR = secretsDir;

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
        (lib.optionalAttrs cfg.openai.enable {OPENAI_MODEL = cfg.openai.model;})
        (lib.optionalAttrs cfg.smtp.enable
          {
            SMTP_AUTH_STRATEGY = cfg.smtp.security;
            SMTP_FROM_NAME = cfg.smtp.from.name;
            SMTP_FROM_EMAIL = cfg.smtp.from.address;
          })
      ];
    };

    systemd.tmpfiles.settings."10-mealie"."/var/lib/mealie/secrets".d = {
      user = config.systemd.services.mealie.serviceConfig.User;
      group = config.systemd.services.mealie.serviceConfig.User;
      mode = "0700";
      age = "-";
    };

    sops.secrets = {
      "mealie/openai_api_key" = mkSecret cfg.openai.apiKey "openai_api_key";
      "mealie/oidc_client_secret" = mkSecret cfg.oidc.clientSecret "oidc_client_secret";
      "mealie/smtp/host" = mkSecret cfg.smtp.host "smtp_host";
      "mealie/smtp/port" = mkSecret cfg.smtp.port "smtp_port";
      "mealie/smtp/username" = mkSecret cfg.smtp.username "smtp_user";
      "mealie/smtp/password" = mkSecret cfg.smtp.password "smtp_password";
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
