{
  config,
  lib,
  pkgs-unstable,
  pkgs-chromium,
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

    systemd.services.flaresolverr = let
      chromium = pkgs-chromium.chromium;
      flaresolverr = pkgs-unstable.flaresolverr.override {
        # Need to downgrade from latest chromium per
        # https://github.com/FlareSolverr/FlareSolverr/issues/1318
        inherit chromium;

        # The chromedriver for Chrome 126 was packaged differently than 129, so we need to change
        # how it's built to match what undetected-chromedriver expects. This copies the build process for 129 from:
        # https://github.com/NixOS/nixpkgs/blob/c31898ad/pkgs/development/tools/selenium/chromedriver/source.nix
        undetected-chromedriver = pkgs-unstable.undetected-chromedriver.override {
          chromedriver = chromium.mkDerivation (_: {
            name = "chromedriver";
            packageName = "chromedriver";

            buildTargets = ["chromedriver.unstripped"];

            installPhase = ''
              install -Dm555 $buildPath/chromedriver.unstripped $out/bin/chromedriver
            '';

            postFixup = null;

            meta =
              chromium.meta
              // {
                homepage = "https://chromedriver.chromium.org/";
                description = "WebDriver server for running Selenium tests on Chrome";
                longDescription = ''
                  WebDriver is an open source tool for automated testing of webapps across
                  many browsers. It provides capabilities for navigating to web pages, user
                  input, JavaScript execution, and more. ChromeDriver is a standalone
                  server that implements the W3C WebDriver standard.
                '';
                mainProgram = "chromedriver";
              };
          });
        };
      };
    in {
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
        ExecStart = lib.getExe flaresolverr;
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
