{
  config,
  lib,
  ...
}: let
  cfg = config.components.vaultwarden;

  secretSpec = name: secret: {
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

  pushNotificationEnv =
    if cfg.pushNotifications.enable
    then ''
      PUSH_INSTALLATION_ID=${config.sops.placeholder.vaultwardenPushInstallationId}
      PUSH_INSTALLATION_KEY=${config.sops.placeholder.vaultwardenPushInstallationKey}
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

    pushNotifications = {
      enable = lib.mkEnableOption "Enable push notifications";
      installationId = secretSpec "installation ID" "push/installation_id";
      installationKey = secretSpec "installation key" "push/installation_key";
    };
  };

  config = lib.mkIf cfg.enable {
    components.database = {
      enable = true;
      databases = ["vaultwarden"];
    };

    services.vaultwarden = {
      enable = true;
      dbBackend = "postgresql";

      config = {
        ROCKET_ADDRESS = "unix:/run/vaultwarden.sock";
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

        IP_HEADER = "CF-Connecting-IP";
      };
    };

    sops.secrets.vaultwardenPushInstallationId = lib.mkIf cfg.pushNotifications.enable (secretInstance cfg.pushNotifications.installationId);
    sops.secrets.vaultwardenPushInstallationKey = lib.mkIf cfg.pushNotifications.enable (secretInstance cfg.pushNotifications.installationKey);

    sops.templates."vaultwarden.env" = {
      content = ''
        ${pushNotificationEnv}
      '';

      owner = config.users.users.vaultwarden.name;
      group = config.users.users.vaultwarden.group;
    };
  };
}
