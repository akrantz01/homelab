{
  config,
  lib,
  pkgs-unstable,
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
      package = pkgs-unstable.actual-server.overrideAttrs (oldAttrs: {
        patches =
          (oldAttrs.patches or [])
          ++ [
            ./trust-proxy.patch
          ];
      });

      openFirewall = false;

      settings = {
        trustedProxies = [];
      };
    };

    components.reverseProxy.hosts.${cfg.domain}.locations."/".proxyTo = let
      actual = config.services.actual;
      host = actual.settings.hostname;
      port = builtins.toString actual.settings.port;
    in "http://[${host}]:${port}";
  };
}
