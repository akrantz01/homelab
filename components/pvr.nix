{
  config,
  lib,
  pkgs-unstable,
  pkgs-sonarr,
  ...
}: let
  cfg = config.components.pvr;

  mkDomainOption = for:
    lib.mkOption {
      type = lib.types.str;
      default = "${lib.strings.toLower for}.${cfg.baseDomain}";
      description = "The domain to use for the ${for} UI";
    };
  mkVirtualHost = port: {
    locations."/".proxyTo = "http://[::1]:${toString port}";
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
      package = pkgs-sonarr.sonarr;
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

    components.reverseProxy.hosts = {
      ${cfg.domains.bazarr} = mkVirtualHost config.services.bazarr.listenPort;
      ${cfg.domains.jellyseerr} = mkVirtualHost config.services.jellyseerr.port;
      ${cfg.domains.radarr} = mkVirtualHost 7878;
      ${cfg.domains.sonarr} = mkVirtualHost 8989;
      ${cfg.domains.prowlarr} = mkVirtualHost 9696;
    };
  };
}
