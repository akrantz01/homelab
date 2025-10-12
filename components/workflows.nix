{
  config,
  extra,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.workflows;
  user = config.users.users.n8n.name;
  group = config.users.groups.n8n.name;
in {
  options.components.workflows = {
    enable = lib.mkEnableOption "Enable the workflows component";
    sopsFile = extra.mkSecretSourceOption config;

    domain = lib.mkOption {
      type = lib.types.str;
      example = "workflows.example.com";
      description = "Where to access the workflows instance";
    };

    encryptionKey = extra.mkSecretOption "credential encryption key" "workflows/encryption-key";

    email = {
      host = extra.mkSecretOption "hostname of the SMTP server" "workflows/smtp/host";
      port = extra.mkSecretOption "port of the SMTP server" "workflows/smtp/port";
      username = extra.mkSecretOption "username for the SMTP server" "workflows/smtp/username";
      password = extra.mkSecretOption "password for the SMTP server" "workflows/smtp/password";

      security = lib.mkOption {
        type = lib.types.enum ["none" "starttls" "tls"];
        default = "starttls";
        example = "starttls";
        description = ''
          The security method to use for the SMTP server. `none` means no security,
          `starttls` uses implicit TLS, and `tls` uses explicit TLS.
        '';
      };

      from = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Workflows";
          description = "The name to use for the sender of the email";
        };
        address = lib.mkOption {
          type = lib.types.str;
          default = "no-reply@${cfg.domain}";
          description = "The email address to use for the sender of the email";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    components.database.databases = ["n8n"];

    services.n8n = {
      enable = true;
      openFirewall = false;

      webhookUrl = "https://${cfg.domain}";
    };

    systemd.services.n8n = {
      environment = {
        N8N_LISTEN_ADDRESS = "::1";
        N8N_PORT = "5678";
        N8N_PROTOCOL = "http";
        N8N_PROXY_HOPS = "1";

        N8N_LOG_LEVEL = "info";
        N8N_LOG_OUTPUT = "console";
        N8N_LOG_FORMAT = "text";

        DB_TYPE = "postgresdb";
        DB_POSTGRESDB_HOST = "/run/postgresql";
        DB_POSTGRESDB_PORT = "5432";
        DB_POSTGRESDB_USER = "n8n";

        N8N_PERSONALIZATION_ENABLED = "false";
        N8N_VERSION_NOTIFICATIONS_ENABLED = "false";
        N8N_DIAGNOSTICS_ENABLED = "false";
        N8N_HIRING_BANNER_ENABLED = "false";
        N8N_HIDE_USAGE_PAGE = "false";
        N8N_ONBOARDING_FLOW_DISABLED = "true";

        GENERIC_TIMEZONE = config.time.timeZone;
        N8N_ENCRYPTION_KEY_FILE = config.sops.secrets."workflows/encryption-key".path;

        N8N_DEFAULT_BINARY_DATA_MODE = "filesystem";
        N8N_COMMUNITY_PACKAGES_ENABLED = "true";
        N8N_PYTHON_ENABLED = "true";
        N8N_VERIFIED_PACKAGES_ENABLED = "true";
        N8N_UNVERIFIED_PACKAGES_ENABLED = "true";

        EXECUTIONS_MODE = "regular"; # in-memory
        EXECUTIONS_TIMEOUT = "-1";
        EXECUTIONS_TIMEOUT_MAX = "3600";
        N8N_CONCURRENCY_PRODUCTION_LIMIT = "-1";

        # TODO: evaluate adding runners support
        # https://docs.n8n.io/hosting/configuration/environment-variables/task-runners/

        N8N_BLOCK_ENV_ACCESS_IN_NODE = "true";
        N8N_BLOCK_FILE_ACCESS_TO_N8N_FILES = "true";

        N8N_EMAIL_MODE = "smtp";
        N8N_SMTP_HOST_FILE = config.sops.secrets."workflows/smtp/host".path;
        N8N_SMTP_PORT_FILE = config.sops.secrets."workflows/smtp/port".path;
        N8N_SMTP_USER_FILE = config.sops.secrets."workflows/smtp/username".path;
        N8N_SMTP_PASS_FILE = config.sops.secrets."workflows/smtp/password".path;
        N8N_SMTP_SENDER = "${cfg.email.from.name} <${cfg.email.from.address}>";
        N8N_SMTP_SSL = lib.trivial.boolToString (cfg.email.security == "tls");
        N8N_SMTP_STARTTLS = lib.trivial.boolToString (cfg.email.security == "starttls");
      };

      serviceConfig = {
        User = user;
        Group = group;
        ExecStart = lib.mkForce "${pkgs-unstable.n8n}/bin/n8n";
      };
    };

    users.users.n8n = {
      inherit group;
      createHome = true;
      home = "/var/lib/n8n";
      isSystemUser = true;
    };
    users.groups.n8n = {};

    sops.secrets = let
      owner = user;
      instance = key: {
        inherit key owner group;
        inherit (cfg) sopsFile;

        restartUnits = [config.systemd.services.n8n.name];
      };
    in {
      "workflows/encryption-key" = instance cfg.encryptionKey;
      "workflows/smtp/host" = instance cfg.email.host;
      "workflows/smtp/port" = instance cfg.email.port;
      "workflows/smtp/username" = instance cfg.email.username;
      "workflows/smtp/password" = instance cfg.email.password;
    };
  };
}
