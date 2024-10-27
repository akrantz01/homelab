{
  config,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.atuin;
in {
  options.components.atuin = {
    enable = lib.mkEnableOption "Enable the Atuin component";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "shell.example.com";
      description = "The domain to use for the Atuin instance";
    };
  };

  config = lib.mkIf cfg.enable {
    services.atuin = {
      enable = true;
      package = pkgs-unstable.atuin;

      host = "::1";
      port = 2886;

      openRegistration = false;
      openFirewall = false;

      database.uri = "postgresql://atuin?host=/var/run/postgresql";
      database.createLocally = true;
    };

    components.reverseProxy.hosts.${cfg.domain}.locations."/".proxyTo = let
      atuin = config.services.atuin;
      host = atuin.host;
      port = builtins.toString atuin.port;
    in "http://[${host}]:${port}";
  };
}
