{
  config,
  lib,
  pkgs,
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
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;

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
  };
}
