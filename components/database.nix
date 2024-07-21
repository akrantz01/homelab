{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.components.database;
in {
  options.components.database.enable = lib.mkEnableOption "Enable the database component";

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;

      enableJIT = true;
      enableTCPIP = false;
    };
  };
}
