{
  config,
  lib,
  extra,
  pkgs-unstable,
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
      # TODO: switch to stable once upgraded to 25.11
      package = pkgs-unstable.meilisearch;

      environment = "production";
      masterKeyEnvironmentFile = config.sops.templates."meilisearch.env".path;
    };

    sops = let
      units = [config.systemd.services.meilisearch.name];
    in {
      secrets."meilisearch/master_key" = {
        inherit (cfg) sopsFile;
        key = cfg.masterKey;

        restartUnits = units;
      };

      templates."meilisearch.env" = {
        content = ''
          MEILI_MASTER_KEY=${config.sops.placeholder."meilisearch/master_key"}
        '';

        restartUnits = units;
      };
    };
  };
}
