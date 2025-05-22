{
  config,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.pvr;

  mkDomainOption = for: {
    name = lib.mkOption {
      type = lib.types.str;
      default = "${lib.strings.toLower for}.${cfg.baseDomain}";
      description = "The domain to use for the ${for} UI";
    };
    proxyAuth = lib.mkEnableOption "Enable proxy authentication for ${for}";
  };
in {
  options.components.pvr = {
    enable = lib.mkEnableOption "Enable the PVR component";

    baseDomain = lib.mkOption {
      type = lib.types.str;
      default = "example.com";
      description = "The base domain to use for the PVR UI";
    };
    domains = {
      bazarr = mkDomainOption "Bazarr";
      jellyseerr = mkDomainOption "Jellyseer";
      prowlarr = mkDomainOption "Prowlarr";
      radarr = mkDomainOption "Radarr";
      sonarr = mkDomainOption "Sonarr";
    };
  };

  config = lib.mkIf cfg.enable {
    services.radarr = {
      enable = true;
      package = pkgs-unstable.radarr;
      openFirewall = false;
    };

    services.sonarr = {
      enable = true;
      package = pkgs-unstable.sonarr;
      openFirewall = false;
    };

    services.prowlarr = {
      enable = true;
      package = pkgs-unstable.prowlarr;
      openFirewall = false;
    };

    services.bazarr = {
      enable = true;
      package = pkgs-unstable.bazarr;
      openFirewall = false;
    };

    services.jellyseerr = {
      enable = true;
      package = pkgs-unstable.jellyseerr;
      openFirewall = false;
    };
    systemd.services.jellyseerr = {
      environment.CONFIG_DIRECTORY = "/var/lib/jellyseerr/config";
      serviceConfig = {
        WorkingDirectory = lib.mkForce "/";
        BindPaths = lib.mkForce [];
      };
    };

    components.reverseProxy.hosts = let
      mkVirtualHost = domain: port: {
        ${domain.name} = {
          locations."/".proxyTo = "http://[::1]:${toString port}";
          forwardAuth = domain.proxyAuth;
        };
      };
    in
      lib.attrsets.mergeAttrsList [
        (mkVirtualHost cfg.domains.bazarr config.services.bazarr.listenPort)
        (mkVirtualHost cfg.domains.jellyseerr config.services.jellyseerr.port)
        (mkVirtualHost cfg.domains.radarr 7878)
        (mkVirtualHost cfg.domains.sonarr 8989)
        (mkVirtualHost cfg.domains.prowlarr 9696)
      ];
  };
}
