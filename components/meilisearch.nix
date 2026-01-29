{
  config,
  lib,
  extra,
  pkgs-stable,
  ...
}: let
  cfg = config.components.meilisearch;
in {
  options.components.meilisearch = {
    enable = lib.mkEnableOption "Enable the Meiliesearch component";
    sopsFile = extra.mkSecretSourceOption config;

    masterKey = extra.mkSecretOption "master key" "meilisearch/master_key";
  };

  config = lib.mkIf cfg.enable {
    services.meilisearch = {
      enable = true;
      package = pkgs-stable.meilisearch;

      settings.env = "production";
      masterKeyFile = config.sops.secrets."meilisearch/master_key".path;
    };

    sops.secrets."meilisearch/master_key" = {
      inherit (cfg) sopsFile;
      key = cfg.masterKey;

      restartUnits = [config.systemd.services.meilisearch.name];
    };
  };
}
