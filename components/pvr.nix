{
  config,
  lib,
  pkgs-stable,
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

    # Manually copying over the Bazarr service definition as it does not support overriding the package
    systemd.services.bazarr = {
      description = "bazarr";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = rec {
        Type = "simple";
        User = config.users.users.bazarr.name;
        Group = config.users.users.bazarr.group;
        StateDirectory = "bazarr";
        SyslogIdentifier = "bazarr";
        ExecStart = pkgs-stable.writeShellScript "start-bazarr" ''
          ${pkgs-unstable.bazarr}/bin/bazarr \
            --config '/var/lib/${StateDirectory}' \
            --port ${toString config.services.bazarr.listenPort} \
            --no-update True
        '';
        Restart = "on-failure";
      };
    };

    users.groups.bazarr = {};
    users.users.bazarr = {
      isSystemUser = true;
      group = config.users.groups.bazarr.name;
      home = "/var/lib/${config.systemd.services.bazarr.serviceConfig.StateDirectory}";
    };

    # Manually copying over the Jellyseer service definition as it does not support overriding the package
    systemd.services.jellyseerr = let
      jellyseerr = pkgs-unstable.jellyseerr;
    in {
      description = "Jellyseerr, a requests manager for Jellyfin";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      environment.PORT = toString config.services.jellyseerr.port;
      serviceConfig = {
        Type = "exec";
        StateDirectory = "jellyseerr";
        WorkingDirectory = "${jellyseerr}/libexec/jellyseerr/deps/jellyseerr";
        DynamicUser = true;
        ExecStart = "${jellyseerr}/bin/jellyseerr";
        BindPaths = ["/var/lib/jellyseerr/:${jellyseerr}/libexec/jellyseerr/deps/jellyseerr/config/"];
        Restart = "on-failure";
        ProtectHome = true;
        ProtectSystem = "strict";
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        NoNewPrivileges = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
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
