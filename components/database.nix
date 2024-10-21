{
  config,
  lib,
  pkgs-stable,
  ...
}: let
  cfg = config.components.database;
in {
  options.components.database = {
    enable = lib.mkEnableOption "Enable the database component";

    databases = lib.mkOption {
      default = [];
      type = lib.types.listOf lib.types.str;
      description = "List of databases and their corresponding users to create";
    };

    backups = {
      enable = lib.mkEnableOption "Enable database backups";
      location = lib.mkOption {
        type = lib.types.str;
        default = "/mnt/backups/postgres";
        description = "Location to store database backups";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = pkgs-stable.postgresql_16;

      enableJIT = true;
      enableTCPIP = false;

      ensureDatabases = cfg.databases;
      ensureUsers =
        builtins.map (db: {
          name = db;
          ensureDBOwnership = true;
        })
        cfg.databases;
    };

    services.postgresqlBackup = {
      enable = cfg.backups.enable;
      location = cfg.backups.location;

      backupAll = true;
      compression = "zstd";
    };
  };
}
