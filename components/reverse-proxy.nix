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

      commonHttpConfig = let
        realIpsFromList = lib.strings.concatMapStringsSep "\n" (src: "set_real_ip_from ${src};");
        fileToList = path: lib.strings.splitString "\n" (builtins.readFile path);

        cloudflareIpV4 = fileToList (pkgs.fetchurl {
          url = "https://www.cloudflare.com/ips-v4";
          sha256 = "sha256-8Cxtg7wBqwroV3Fg4DbXAMdFU1m84FTfiE5dfZ5Onns=";
        });
        cloudflareIpV6 = fileToList (pkgs.fetchurl {
          url = "https://www.cloudflare.com/ips-v6";
          sha256 = "sha256-np054+g7rQDE3sr9U8Y/piAp89ldto3pN9K+KCNMoKk=";
        });
      in ''
        ${realIpsFromList cloudflareIpV4}
        ${realIpsFromList cloudflareIpV6}
        real_ip_header CF-Connecting-IP;
      '';
    };
  };
}
