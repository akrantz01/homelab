{
  config,
  lib,
  pkgs-unstable,
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
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;

    locations."/".proxyPass = "http://[::1]:${toString port}";
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
      # Bazarr does not allow overriding the package
      # package = pkgs-unstable.bazarr;
      openFirewall = false;
    };

    systemd.services.flaresolverr = {
      description = "FlareSolverr";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        HOME = "/run/flaresolverr";
        PORT = "8191";
      };

      serviceConfig = {
        SyslogIdentifier = "flaresolverr";
        Restart = "always";
        RestartSec = 5;
        Type = "simple";
        DynamicUser = true;
        RuntimeDirectory = "flaresolverr";
        WorkingDirectory = "/run/flaresolverr";
        ExecStart = lib.getExe pkgs-unstable.flaresolverr;
        TimeoutStopSec = 30;
      };
    };

    services.nginx.virtualHosts = {
      ${cfg.domains.bazarr} = mkVirtualHost config.services.bazarr.listenPort;
      ${cfg.domains.radarr} = mkVirtualHost 7878;
      ${cfg.domains.sonarr} = mkVirtualHost 8989;
      ${cfg.domains.prowlarr} = mkVirtualHost 9696;
    };
  };
}
