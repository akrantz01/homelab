{
  config,
  extra,
  lib,
  pkgs-stable,
  pkgs-unstable,
  settings,
  ...
}: let
  cfg = config.components.reverseProxy;
  acme = settings.acme;

  locationsType = lib.types.submodule {
    options = {
      proxyTo = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "The URL to proxy to";
      };

      proxyWebsockets = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to proxy websockets";
      };

      recommendedProxySettings = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to apply recommended proxy settings";
      };

      return = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Adds a return directive, for e.g. redirections.";
      };

      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "These lines go to the end of the upstream verbatim";
      };

      priority = lib.mkOption {
        type = lib.types.int;
        default = 1000;
        description = "The priority of the location";
      };
    };
  };

  virtualHostsType = lib.types.submodule {
    options = {
      locations = lib.mkOption {
        type = lib.types.attrsOf locationsType;
        default = {};
        description = "Declarative location config";
      };

      listenAddresses = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "The listen address for the virtual host";
      };

      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "These lines go to the end of the upstream verbatim";
      };
    };
  };

  backendsType = lib.types.submodule {
    options = {
      servers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "The servers to use for the backend";
      };

      keepAlive = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = "The keep alive timeout for the backend";
      };
    };
  };
in {
  options.components.reverseProxy = {
    enable = lib.mkEnableOption "Enable the reverse proxy component";
    sopsFile = extra.mkSecretSourceOption config;

    defaultListenAddresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["0.0.0.0"] ++ lib.optional config.networking.enableIPv6 "[::0]";
      description = "The default listen address for the reverse proxy";
    };

    hosts = lib.mkOption {
      type = lib.types.attrsOf virtualHostsType;
      default = {};
      description = "Virtual hosts to configure";
    };

    backends = lib.mkOption {
      type = lib.types.attrsOf backendsType;
      default = {};
      description = "Backends to proxy virtual hosts to";
    };
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

    sops.secrets = lib.attrsets.genAttrs (lib.attrsets.attrValues acme.provider.credentials) (key: {inherit (cfg) sopsFile;});

    services.nginx = {
      enable = true;
      enableReload = true;

      package = pkgs-unstable.nginxQuic;
      additionalModules = with pkgs-unstable.nginxModules; [moreheaders];

      inherit (cfg) defaultListenAddresses;

      recommendedTlsSettings = true;
      recommendedProxySettings = true;
      recommendedOptimisation = true;
      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedZstdSettings = true;

      commonHttpConfig = let
        realIpsFromList = lib.strings.concatMapStringsSep "\n" (src: "set_real_ip_from ${src};");
        fileToList = path: lib.strings.splitString "\n" (builtins.readFile path);

        cloudflareIpV4 = fileToList (pkgs-stable.fetchurl {
          url = "https://www.cloudflare.com/ips-v4";
          sha256 = "sha256-8Cxtg7wBqwroV3Fg4DbXAMdFU1m84FTfiE5dfZ5Onns=";
        });
        cloudflareIpV6 = fileToList (pkgs-stable.fetchurl {
          url = "https://www.cloudflare.com/ips-v6";
          sha256 = "sha256-np054+g7rQDE3sr9U8Y/piAp89ldto3pN9K+KCNMoKk=";
        });
      in ''
        ${realIpsFromList cloudflareIpV4}
        ${realIpsFromList cloudflareIpV6}
        real_ip_header CF-Connecting-IP;
      '';

      upstreams =
        lib.attrsets.mapAttrs (name: backend: {
          servers = lib.attrsets.genAttrs backend.servers (server: {});
          extraConfig = ''
            keepalive ${builtins.toString backend.keepAlive};
          '';
        })
        cfg.backends;

      virtualHosts =
        lib.attrsets.mapAttrs (name: host: {
          forceSSL = true;
          enableACME = true;
          acmeRoot = null;

          inherit (host) listenAddresses extraConfig;

          locations =
            lib.attrsets.mapAttrs (path: location: {
              inherit (location) proxyWebsockets recommendedProxySettings return extraConfig priority;
              proxyPass = location.proxyTo;
            })
            host.locations;
        })
        cfg.hosts;
    };
  };
}
