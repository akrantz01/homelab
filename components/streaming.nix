{
  config,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.streaming;
in {
  options.components.streaming = {
    enable = lib.mkEnableOption "Enable the streaming component";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "streaming.example.com";
      description = "The domain to use for the streaming instance";
    };

    listenAddresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "The listen addresses for the reverse proxy virtual host";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.components.reverseProxy.enable;
        message = "The reverse proxy component must be enabled to use streaming";
      }
    ];

    services.jellyfin = {
      enable = true;
      package = pkgs-unstable.jellyfin;
    };

    components.reverseProxy.hosts.${cfg.domain} = {
      inherit (cfg) listenAddresses;

      extraConfig = ''
        # Security / XSS Mitigation Headers
        # NOTE: X-Frame-Options may cause issues with the webOS app
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options "nosniff";

        # COOP/COEP. Disable if you use external plugins/images/assets
        add_header Cross-Origin-Opener-Policy "same-origin" always;
        add_header Cross-Origin-Embedder-Policy "require-corp" always;
        add_header Cross-Origin-Resource-Policy "same-origin" always;

        # Permissions policy. May cause issues on some clients
        add_header Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), camera=(), clipboard-read=(), display-capture=(), document-domain=(), encrypted-media=(), gamepad=(), geolocation=(), gyroscope=(), hid=(), idle-detection=(), interest-cohort=(), keyboard-map=(), local-fonts=(), magnetometer=(), microphone=(), payment=(), publickey-credentials-get=(), serial=(), sync-xhr=(), usb=(), xr-spatial-tracking=()" always;
      '';

      locations."= /" = {
        return = "302 https://$host/web/";
        priority = 10;
      };

      locations."/" = {
        proxyTo = "http://127.0.0.1:8096";
        priority = 50;

        extraConfig = "proxy_buffering off;";
      };

      locations."/socket" = {
        proxyTo = "http://127.0.0.1:8096";
        proxyWebsockets = true;
        priority = 50;
      };
    };
  };
}
