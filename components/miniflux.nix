{
  config,
  extra,
  lib,
  pkgs-stable,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.miniflux;

  oauth2Enabled = cfg.oauth2.provider != null;
in {
  options.components.miniflux = {
    enable = lib.mkEnableOption "Enable the Miniflux component";
    sopsFile = extra.mkSecretSourceOption config;

    domain = lib.mkOption {
      type = lib.types.str;
      example = "reader.example.com";
      description = "The domain to use for the Miniflux instance";
    };

    oauth2 = {
      provider = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        example = "google";
        default = null;
        description = "The OAuth2 provider to use for authentication. Can be 'google' or 'oidc'.";
      };

      discoveryEndpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        example = "https://accounts.google.com/.well-known/openid-configuration";
        default = null;
        description = "The OIDC discovery endpoint to use for authentication.";
      };

      clientId = extra.mkSecretOption "OAuth2 client ID" "miniflux/client_id";
      clientSecret = extra.mkSecretOption "OAuth2 client secret" "miniflux/client_secret";
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
        assertion = cfg.oauth2.provider == null || cfg.oauth2.provider == "google" || cfg.oauth2.provider == "oidc";
        message = "The OIDC provider must be either 'google' or 'oidc'";
      }
      {
        assertion = !oauth2Enabled || cfg.oauth2.discoveryEndpoint != null;
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

        DISABLE_LOCAL_AUTH = 1;

        WEBAUTHN = 1;

        OAUTH2_PROVIDER = lib.mkIf oauth2Enabled cfg.oauth2.provider;
        OAUTH2_OIDC_DISCOVERY_ENDPOINT = lib.mkIf oauth2Enabled cfg.oauth2.discoveryEndpoint;
        OAUTH2_CLIENT_ID_FILE = lib.mkIf oauth2Enabled "%d/oauth2-client-id";
        OAUTH2_CLIENT_SECRET_FILE = lib.mkIf oauth2Enabled "%d/oauth2-client-secret";
        OAUTH2_REDIRECT_URL = "https://${cfg.domain}/oauth2/oidc/callback";
        OAUTH2_USER_CREATION = 1;

        # No admin user here, we'll handle everything through OIDC
        CREATE_ADMIN = lib.mkForce 0;
      };
    };

    systemd.services.miniflux.serviceConfig.LoadCredential = lib.mkIf oauth2Enabled [
      "oauth2-client-id:${config.sops.secrets."miniflux/client-id".path}"
      "oauth2-client-secret:${config.sops.secrets."miniflux/client-secret".path}"
    ];

    components.reverseProxy.hosts.${cfg.domain}.locations."/".proxyTo = "http://${config.services.miniflux.config.LISTEN_ADDR}";

    sops.secrets = lib.mkIf oauth2Enabled {
      "miniflux/client-id" = {
        inherit (cfg) sopsFile;
        key = cfg.oauth2.clientId;
      };
      "miniflux/client-secret" = {
        inherit (cfg) sopsFile;
        key = cfg.oauth2.clientSecret;
      };
    };
  };
}
