{
  config,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.vaultwarden;

  listenAddress = "::1";
  listenPort = "8936";

  mkSecretOption = name: secret: {
    name = lib.mkOption {
      type = lib.types.str;
      default = "vaultwarden/${secret}";
      description = "The name of the ${name} secret";
    };
    key = lib.mkOption {
      type = lib.types.str;
      default = "vaultwarden/${secret}";
      description = "The key used to lookup the ${name} secret in the SOPS file";
    };
    file = lib.mkOption {
      type = lib.types.path;
      default = config.sops.defaultSopsFile;
      description = "The path to the SOPS file containing the key";
    };
  };
  secretInstance = options: {
    name = options.name;
    key = options.key;
    sopsFile = options.file;

    owner = config.users.users.vaultwarden.name;
    group = config.users.users.vaultwarden.group;

    restartUnits = [config.systemd.services.vaultwarden.name];
  };

  adminEnv =
    if cfg.admin.enable
    then ''
      ADMIN_TOKEN=${config.sops.placeholder.vaultwardenAdminToken}
    ''
    else "";

  pushNotificationEnv =
    if cfg.pushNotifications.enable
    then ''
      PUSH_INSTALLATION_ID=${config.sops.placeholder.vaultwardenPushInstallationId}
      PUSH_INSTALLATION_KEY=${config.sops.placeholder.vaultwardenPushInstallationKey}
    ''
    else "";

  smtpEnv =
    if cfg.smtp.enable
    then ''
      SMTP_HOST=${config.sops.placeholder.vaultwardenSmtpHost}
      SMTP_PORT=${config.sops.placeholder.vaultwardenSmtpPort}
      SMTP_USERNAME=${config.sops.placeholder.vaultwardenSmtpUsername}
      SMTP_PASSWORD=${config.sops.placeholder.vaultwardenSmtpPassword}
    ''
    else "";
in {
  options.components.vaultwarden = {
    enable = lib.mkEnableOption "Enable the Vaultwarden component";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "vault.example.com";
      description = "The domain to use for the Vaultwarden instance";
    };

    admin = {
      enable = lib.mkEnableOption "Enable the admin interface";
      token = mkSecretOption "admin token" "admin_token";
      public = lib.mkEnableOption "Disable authentication for the admin page. Only meant to be used with a separate auth layer";
    };

    pushNotifications = {
      enable = lib.mkEnableOption "Enable push notifications";
      installationId = mkSecretOption "installation ID" "push/installation_id";
      installationKey = mkSecretOption "installation key" "push/installation_key";
    };

    smtp = {
      enable = lib.mkEnableOption "Enable SMTP for sending emails";

      host = mkSecretOption "SMTP host" "smtp/host";
      port = mkSecretOption "SMTP port" "smtp/port";
      username = mkSecretOption "SMTP username" "smtp/username";
      password = mkSecretOption "SMTP password" "smtp/password";

      security = lib.mkOption {
        type = lib.types.str;
        default = "starttls";
        description = "The security method to use for the SMTP connection (starttls, force_tls, off)";
      };

      from = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Vaultwarden";
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
        message = "The database component must be enabled to use Vaultwarden";
      }
      {
        assertion = config.components.reverseProxy.enable;
        message = "The reverse proxy component must be enabled to use Vaultwarden";
      }
    ];

    components.database.databases = ["vaultwarden"];

    services.vaultwarden = {
      enable = true;
      package = pkgs-unstable.vaultwarden;

      dbBackend = "postgresql";

      environmentFile = config.sops.templates."vaultwarden.env".path;
      config = {
        ROCKET_ADDRESS = listenAddress;
        ROCKET_PORT = listenPort;

        DOMAIN = "https://" + cfg.domain;

        WEB_VAULT_ENABLED = true;

        DATABASE_URL = "postgresql://vaultwarden?host=/run/postgresql";
        DATABASE_MAX_CONNS = 10;

        ENABLE_WEBSOCKET = true;

        PUSH_ENABLED = cfg.pushNotifications.enable;
        PUSH_RELAY_URI = "https://push.bitwarden.com";
        PUSH_IDENTITY_URI = "https://identity.bitwarden.com";

        SENDS_ENABLED = true;

        SIGNUPS_ALLOWED = false;
        SIGNUPS_VERIFY = true;

        INVITATIONS_ALLOWED = true;

        DISABLE_ADMIN_TOKEN = cfg.admin.enable && cfg.admin.public;

        SMTP_FROM = cfg.smtp.from.address;
        SMTP_FROM_NAME = cfg.smtp.from.name;
        SMTP_SECURITY = cfg.smtp.security;
        SMTP_TIMEOUT = 15;

        IP_HEADER = "CF-Connecting-IP";
      };
    };

    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;

      locations."/" = {
        proxyPass = "http://[${listenAddress}]:${listenPort}";
        proxyWebsockets = true;
      };
    };

    sops.secrets.vaultwardenPushInstallationId = lib.mkIf cfg.pushNotifications.enable (secretInstance cfg.pushNotifications.installationId);
    sops.secrets.vaultwardenPushInstallationKey = lib.mkIf cfg.pushNotifications.enable (secretInstance cfg.pushNotifications.installationKey);
    sops.secrets.vaultwardenSmtpHost = lib.mkIf cfg.smtp.enable (secretInstance cfg.smtp.host);
    sops.secrets.vaultwardenSmtpPort = lib.mkIf cfg.smtp.enable (secretInstance cfg.smtp.port);
    sops.secrets.vaultwardenSmtpUsername = lib.mkIf cfg.smtp.enable (secretInstance cfg.smtp.username);
    sops.secrets.vaultwardenSmtpPassword = lib.mkIf cfg.smtp.enable (secretInstance cfg.smtp.password);
    sops.secrets.vaultwardenAdminToken = lib.mkIf cfg.admin.enable (secretInstance cfg.admin.token);

    sops.templates."vaultwarden.env" = {
      content = ''
        ${adminEnv}
        ${pushNotificationEnv}
        ${smtpEnv}
      '';

      owner = config.users.users.vaultwarden.name;
      group = config.users.users.vaultwarden.group;
    };
  };
}
