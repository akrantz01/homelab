{
  self,
  config,
  host,
  lib,
  ...
}: let
  cfg = config.components.vaultwarden;

  secretSpec = name: secret: {
    keyRef = lib.mkOption {
      type = lib.types.str;
      default = "vaultwarden/push_notifications/${secret}";
      example = "vaultwarden/secret";
      description = "The reference to the secret containing the ${name}";
    };
    path = lib.mkOption {
      type = lib.types.str;
      example = "${self}/secrets/nix/${host.hostname}/default.yaml";
      description = "The path to the file containing the SOPS encrypted secrets";
    };
  };
in {
  options.components.vaultwarden = {
    enable = lib.mkEnableOption "Enable the Vaultwarden component";

    pushNotifications = {
      enable = lib.mkEnableOption "Enable push notifications";
      installationId = secretSpec "installation ID" "installation_id";
      installationKey = secretSpec "installation key" "installation_key";
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

        WEB_VAULT_ENABLED = true;

        DATABASE_URL = "postgresql://vaultwarden?host=/run/postgresql";
        DATABASE_MAX_CONNS = 10;

        ENABLE_WEBSOCKET = true;

        SENDS_ENABLED = true;
      };
    };
  };
}
