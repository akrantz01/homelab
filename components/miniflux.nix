{
  config,
  lib,
  pkgs-stable,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.miniflux;

  oidcEnabled = cfg.oidc.provider != null;
in {
  options.components.miniflux = {
    enable = lib.mkEnableOption "Enable the Miniflux component";
    domain = lib.mkOption {
      type = lib.types.str;
      example = "reader.example.com";
      description = "The domain to use for the Miniflux instance";
    };

    oidc = {
      provider = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        example = "google";
        default = null;
        description = "The OIDC provider to use for authentication. Can be 'google' or 'oidc'.";
      };

      discoveryEndpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        example = "https://accounts.google.com/.well-known/openid-configuration";
        default = null;
        description = "The OIDC discovery endpoint to use for authentication.";
      };

      clientId = {
        key = lib.mkOption {
          type = lib.types.str;
          default = "miniflux/client_id";
          description = "The key used to lookup the OIDC client ID in the SOPS file";
        };
        file = lib.mkOption {
          type = lib.types.path;
          default = config.sops.defaultSopsFile;
          description = "The path to the SOPS file containing the key";
        };
      };

      clientSecret = {
        key = lib.mkOption {
          type = lib.types.str;
          default = "miniflux/client_secret";
          description = "The key used to lookup the OIDC client secret in the SOPS file";
        };
        file = lib.mkOption {
          type = lib.types.path;
          default = config.sops.defaultSopsFile;
          description = "The path to the SOPS file containing the key";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.components.database.enable;
        message = "The database component must be enabled to use Vaultwarden";
      }
      {
        assertion = config.components.reverseProxy.enable;
        message = "The reverse proxy component must be enabled to use Vaultwarden";
      }
      {
        assertion = cfg.oidc.provider == null || cfg.oidc.provider == "google" || cfg.oidc.provider == "oidc";
        message = "The OIDC provider must be either 'google' or 'oidc'";
      }
      {
        assertion = !oidcEnabled || cfg.oidc.discoveryEndpoint != null;
        message = "The OIDC discovery endpoint must be set when using an OIDC provider";
      }
    ];

    services.miniflux = {
      enable = true;
      package = pkgs-unstable.miniflux;

      createDatabaseLocally = true;
      adminCredentialsFile = pkgs-stable.writeText "miniflux-unused-admin-credentials" "";

      config = {
        BASE_URL = "https://${cfg.domain}";
        HTTPS = 1;

        WEBAUTHN = 1;

        OAUTH2_PROVIDER = lib.mkIf oidcEnabled cfg.oidc.provider;
        OAUTH2_OIDC_DISCOVERY_ENDPOINT = lib.mkIf oidcEnabled cfg.oidc.discoveryEndpoint;
        OAUTH2_CLIENT_ID_FILE = lib.mkIf oidcEnabled config.sops.secrets.minifluxOIDCClientId.path;
        OAUTH2_CLIENT_SECRET_FILE = lib.mkIf oidcEnabled config.sops.secrets.minifluxOIDCClientSecret.path;
        OAUTH2_REDIRECT_URL = "https://${cfg.domain}/oauth2/oidc/callback";
        OAUTH2_USER_CREATION = 1;

        # No admin user here, we'll handle everything through OIDC
        CREATE_ADMIN = lib.mkForce 0;
      };
    };

    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;

      locations."/".proxyPass = "http://${config.services.miniflux.config.LISTEN_ADDR}";
    };

    sops.secrets = lib.mkIf oidcEnabled {
      minifluxOIDCClientId = {
        key = cfg.oidc.clientId.key;
        sopsFile = cfg.oidc.clientId.file;
      };
      minifluxOIDCClientSecret = {
        key = cfg.oidc.clientSecret.key;
        sopsFile = cfg.oidc.clientSecret.file;
      };
    };
  };
}
