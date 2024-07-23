{
  config,
  lib,
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

      host = "::1";
      port = 2886;

      openRegistration = false;
      openFirewall = false;

      database.uri = "postgresql://atuin?host=/var/run/postgresql";
      database.createLocally = true;
    };

    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;

      locations."/".proxyPass = "http://[${config.services.atuin.host}]:${builtins.toString config.services.atuin.port}";
    };
  };
}
