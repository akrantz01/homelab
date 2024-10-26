{
  config,
  lib,
  pkgs-actualbudget,
  ...
}: let
  cfg = config.components.actualbudget;
in {
  options.components.actualbudget = {
    enable = lib.mkEnableOption "Enable the Actual Budget component";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "budget.example.com";
      description = "The domain to use for the Actual Budget instance";
    };
  };

  config = lib.mkIf cfg.enable {
    services.actual = {
      enable = true;
      # TODO: Change to pkgs-unstable.actual-server
      package = pkgs-actualbudget.actual-server;

      openFirewall = false;
    };

    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;

      locations."/".proxyPass = let
        settings = config.services.actual.settings;
        hostname = settings.hostname;
        port = settings.port;
      in "http://[${hostname}]:${builtins.toString port}";
    };
  };
}
