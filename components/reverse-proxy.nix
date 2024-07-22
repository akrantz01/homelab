{
  config,
  lib,
  pkgs,
  settings,
  ...
}: let
  cfg = config.components.reverseProxy;
  acme = settings.acme;
in {
  options.components.reverseProxy = {
    enable = lib.mkEnableOption "Enable the reverse proxy component";
  };

  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;

      defaults = {
        email = acme.email;
        server = acme.server;

        dnsResolver = acme.dnsResolver;
        dnsProvider = acme.provider.name;
        credentialFiles = lib.attrsets.mapAttrs (var: key: config.sops.secrets.${key}.path) acme.provider.credentials;

        reloadServices = ["nginx.service"];
      };
    };

    sops.secrets = lib.attrsets.genAttrs (lib.attrsets.attrValues acme.provider.credentials) (key: {});

    services.nginx = {
      enable = true;
      enableReload = true;

      package = pkgs.nginxQuic;
      additionalModules = with pkgs.nginxModules; [moreheaders];

      recommendedTlsSettings = true;
      recommendedProxySettings = true;
      recommendedOptimisation = true;
      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedZstdSettings = true;
    };
  };
}
