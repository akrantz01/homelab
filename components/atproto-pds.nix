{
  config,
  extra,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.atproto;
in {
  options.components.atproto = {
    enable = lib.mkEnableOption "Enable the AT Proto PDS component";
    sopsFile = extra.mkSecretSourceOption config;

    domain = lib.mkOption {
      type = lib.types.str;
      example = "example.social";
      description = "The domain to use for the PDS service. Cannot be a subdomain";
    };

    adminPassword = extra.mkSecretOption "admin password" "pds/admin_password";
    dpopSecret = extra.mkSecretOption "DPoP signing secret" "pds/dpop_secret";
    jwtSecret = extra.mkSecretOption "JWT signing secret" "pds/jwt_secret";
    rotationKey = extra.mkSecretOption "K256 PLC rotation key" "pds/rotation_key";

    blobstore = {
      location = lib.mkOption {
        type = lib.types.enum ["disk" "s3"];
        default = "disk";
        description = "Where to store blob files";
      };

      path = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/pds/blocks";
        description = "The path to use for the blobstore backend. Only used if the location is set to `disk`.";
      };

      s3 = {
        endpoint = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          example = "https://s3.ca-central-1.amazonaws.com";
          description = "The provider's S3 endpoint URL. Only used if the blobstore backend is set to `s3`";
          default = null;
        };

        bucket = lib.mkOption {
          type = lib.types.str;
          example = "pds";
          description = "The S3 bucket to use for the blobstore backend. Only used if the blobstore backend is set to `s3`.";
        };

        region = lib.mkOption {
          type = lib.types.str;
          example = "us-east-1";
          description = "The S3 region where the bucket was created. Only used if the blobstore backend is set to `s3`.";
        };

        accessKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          example = "pds/s3/access-key";
          default = null;
          description = "The key used to lookup the provider's access key ID secret in the SOPS file. Only used if the blobstore backend is set to `s3`.";
        };

        secretKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          example = "pds/s3/secret-key";
          default = null;
          description = "The key used to lookup the provider's secret access key secret in the SOPS file. Only used if the blobstore backend is set to `s3`.";
        };

        forcePathStyle = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to force path style for bucket access. Only use if the blobstore backend is set to 's3'.";
        };
      };
    };

    smtp = {
      enable = lib.mkEnableOption "Enable SMTP for sending emails";

      host = extra.mkSecretOption "SMTP host" "pds/smtp/host";
      port = extra.mkSecretOption "SMTP port" "pds/smtp/port";
      username = extra.mkSecretOption "SMTP username" "pds/smtp/username";
      password = extra.mkSecretOption "SMTP password" "pds/smtp/password";

      security = lib.mkOption {
        type = lib.types.enum ["force-tls" "starttls" "off"];
        default = "starttls";
        description = "The security method to use for the SMTP connection";
      };

      from = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "PDS";
          description = "The name to use for the from field in emails";
        };
        address = lib.mkOption {
          type = lib.types.str;
          default = "no-reply@${cfg.domain}";
          description = "The email to use for the from field in emails";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.bluesky-pds = {
      enable = true;
      pdsadmin.enable = true;
      package = pkgs-unstable.bluesky-pds;

      environmentFiles = [config.sops.templates."atproto-pds.env".path];
      settings = lib.mergeAttrsList [
        {
          PDS_HOSTNAME = cfg.domain;
          PDS_PORT = 28737;
        }
        (lib.optionalAttrs (cfg.blobstore.location == "disk") {
          PDS_BLOBSTORE_DISK_LOCATION = cfg.blobstore.path;
        })
        (lib.optionalAttrs (cfg.blobstore.location == "s3") (let
          s3 = cfg.blobstore.s3;
        in {
          PDS_BLOBSTORE_DISK_LOCATION = null;
          PDS_BLOBSTORE_S3_BUCKET = s3.bucket;
          PDS_BLOBSTORE_S3_REGION = s3.region;
          PDS_BLOBSTORE_S3_ENDPOINT = lib.mkIf (s3.endpoint != null) s3.endpoint;
          PDS_BLOBSTORE_S3_FORCE_PATH_STYLE = lib.boolToString s3.forcePathStyle;
        }))
        (lib.optionalAttrs cfg.smtp.enable {
          PDS_EMAIL_FROM_ADDRESS = "\"${cfg.smtp.from.name}\" <${cfg.smtp.from.address}>";
        })
      ];
    };

    components.reverseProxy.hosts.${cfg.domain} = {
      aliases = ["*.${cfg.domain}"];

      locations."/" = {
        proxyTo = "http://[::1]:${builtins.toString config.services.bluesky-pds.settings.PDS_PORT}";
        proxyWebsockets = true;
      };
    };

    sops.secrets = let
      mkSecret = key: {
        inherit key;
        inherit (cfg) sopsFile;

        owner = config.users.users.pds.name;
        group = config.users.groups.pds.name;

        restartUnits = [config.systemd.services.bluesky-pds.name];
      };
    in {
      "atproto-pds/admin-password" = mkSecret cfg.adminPassword;
      "atproto-pds/dpop-secret" = mkSecret cfg.dpopSecret;
      "atproto-pds/jwt-secret" = mkSecret cfg.jwtSecret;
      "atproto-pds/rotation-key" = mkSecret cfg.rotationKey;
      "atproto-pds/blobstore/s3/access-key" = lib.mkIf (cfg.blobstore.s3.accessKey != null) (mkSecret cfg.blobstore.s3.accessKey);
      "atproto-pds/blobstore/s3/secret-key" = lib.mkIf (cfg.blobstore.s3.secretKey != null) (mkSecret cfg.blobstore.s3.secretKey);
      "atproto-pds/smtp/host" = lib.mkIf cfg.smtp.enable (mkSecret cfg.smtp.host);
      "atproto-pds/smtp/port" = lib.mkIf cfg.smtp.enable (mkSecret cfg.smtp.port);
      "atproto-pds/smtp/username" = lib.mkIf cfg.smtp.enable (mkSecret cfg.smtp.username);
      "atproto-pds/smtp/password" = lib.mkIf cfg.smtp.enable (mkSecret cfg.smtp.password);
    };

    sops.templates."atproto-pds.env" = {
      content = lib.strings.concatStringsSep "\n" [
        ''
          PDS_ADMIN_PASSWORD=${config.sops.placeholder."atproto-pds/admin-password"}
          PDS_DPOP_SECRET=${config.sops.placeholder."atproto-pds/dpop-secret"}
          PDS_JWT_SECRET=${config.sops.placeholder."atproto-pds/jwt-secret"}
          PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=${config.sops.placeholder."atproto-pds/rotation-key"}
        ''
        (lib.strings.optionalString (cfg.blobstore.location == "s3") ''
          PDS_BLOBSTORE_S3_ACCESS_KEY_ID=${config.sops.placeholder."atproto-pds/blobstore/s3/access-key"}
          PDS_BLOBSTORE_S3_SECRET_ACCESS_KEY=${config.sops.placeholder."atproto-pds/blobstore/s3/secret-key"}
        '')
        (lib.strings.optionalString cfg.smtp.enable (let
          protocol =
            if cfg.smtp.security == "force-tls"
            then "smtps"
            else "smtp";
          host = config.sops.placeholder."atproto-pds/smtp/host";
          port = config.sops.placeholder."atproto-pds/smtp/port";
          username = config.sops.placeholder."atproto-pds/smtp/username";
          password = config.sops.placeholder."atproto-pds/smtp/password";

          query = lib.concatStringsSep "&" [
            "secure=${lib.boolToString (cfg.smtp.security == "force-tls")}"
            "requireTLS=${lib.boolToString (cfg.smtp.security == "starttls")}"
            "ignoreTLS=${lib.boolToString (cfg.smtp.security == "off")}"
          ];
        in "PDS_EMAIL_SMTP_URL=${protocol}://${username}:${password}@${host}:${port}/?${query}"))
      ];

      owner = config.users.users.pds.name;
      group = config.users.users.pds.name;

      restartUnits = [config.systemd.services.bluesky-pds.name];
    };
  };
}
