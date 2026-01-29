{
  config,
  extra,
  lib,
  pkgs-stable,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.workflows;
  user = config.users.users.n8n.name;
  group = config.users.groups.n8n.name;

  listen = {
    host = "::1";
    port = "5678";
  };

  n8n = pkgs-unstable.n8n;

  hooksFile = let
    libPath = "${n8n}/lib/n8n/packages/cli/dist";
    sed = "${pkgs-stable.gnused}/bin/sed";
  in
    pkgs-stable.runCommand "n8n-hooks.js" {src = ./hooks.js;} "${sed} 's|N8N_LIB_PATH|${libPath}|g' $src > $out";
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

    oidc = {
      enabled = lib.mkEnableOption "Enable authentication via OIDC";

      discoveryEndpoint = lib.mkOption {
        type = lib.types.str;
        description = "The OIDC configuration URL";
      };

      clientId = extra.mkSecretOption "the OIDC client ID" "workflows/oidc/client-id";
      clientSecret = extra.mkSecretOption "the OIDC client secret" "workflows/oidc/client-secret";
    };
  };

  config = lib.mkIf cfg.enable {
    components.database.databases = ["n8n"];

    services.n8n = {
      enable = true;
      openFirewall = false;

      environment = {
        N8N_LISTEN_ADDRESS = listen.host;
        N8N_PORT = listen.port;
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
        N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";

        N8N_DEFAULT_BINARY_DATA_MODE = "filesystem";
        N8N_COMMUNITY_PACKAGES_ENABLED = "true";
        N8N_PYTHON_ENABLED = "true";
        N8N_VERIFIED_PACKAGES_ENABLED = "true";
        N8N_UNVERIFIED_PACKAGES_ENABLED = "true";

        EXECUTIONS_MODE = "regular"; # in-memory
        EXECUTIONS_TIMEOUT = "-1";
        EXECUTIONS_TIMEOUT_MAX = "3600";
        N8N_CONCURRENCY_PRODUCTION_LIMIT = "-1";

        # TODO: evaluate using external runners
        # https://docs.n8n.io/hosting/configuration/environment-variables/task-runners/
        N8N_RUNNERS_ENABLED = "true";
        N8N_RUNNERS_MODE = "internal";

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

        SSO_OIDC_ENABLED = lib.trivial.boolToString cfg.oidc.enabled;
        SSO_OIDC_DISCOVERY_ENDPOINT = lib.mkIf cfg.oidc.enabled cfg.oidc.discoveryEndpoint;
        SSO_OIDC_CLIENT_ID_FILE = lib.mkIf cfg.oidc.enabled config.sops.secrets."workflows/oidc/client-id".path;
        SSO_OIDC_CLIENT_SECRET_FILE = lib.mkIf cfg.oidc.enabled config.sops.secrets."workflows/oidc/client-secret".path;

        WEBHOOK_URL = "https://${cfg.domain}";
      };
    };

    systemd.services.n8n = {
      environment = {
        N8N_CONFIG_FILES = lib.mkForce null;
        EXTERNAL_HOOK_FILES = hooksFile;
      };

      serviceConfig = {
        User = user;
        Group = group;
        DynamicUser = lib.mkForce false;
        ExecStart = lib.mkForce "${n8n}/bin/n8n";
      };
    };

    users.users.n8n = {
      inherit group;
      createHome = true;
      home = "/var/lib/n8n";
      isSystemUser = true;
    };
    users.groups.n8n = {};

    components.reverseProxy.hosts.${cfg.domain}.locations."/" = {
      proxyTo = "http://[${listen.host}]:${listen.port}";
      proxyWebsockets = true;
    };

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
      "workflows/oidc/client-id" = lib.mkIf cfg.oidc.enabled (instance cfg.oidc.clientId);
      "workflows/oidc/client-secret" = lib.mkIf cfg.oidc.enabled (instance cfg.oidc.clientSecret);
    };
  };
}
