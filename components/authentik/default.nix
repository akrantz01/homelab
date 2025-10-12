{
  config,
  extra,
  lib,
  pkgs-authentik,
  ...
}: let
  cfg = config.components.authentik;

  database = "authentik";
  redis = config.services.redis.servers.authentik.unixSocket;

  pkg = pkgs-authentik.authentik;

  commonEnvironment = lib.attrsets.mergeAttrsList [
    {
      AUTHENTIK_POSTGRESQL__HOST = "";
      AUTHENTIK_POSTGRESQL__NAME = database;
      AUTHENTIK_POSTGRESQL__USER = database;
      AUTHENTIK_POSTGRESQL__SSL_MODE = "disable";
      # TODO: enable connection pooling

      AUTHENTIK_CACHE__URL = "unix://${redis}";
      AUTHENTIK_BROKER__URL = "redis+socket://${redis}";
      AUTHENTIK_RESULT_BACKEND__URL = "redis+socket://${redis}";
      AUTHENTIK_CHANNEL__URL = "unix://${redis}";

      AUTHENTIK_SECRET_KEY = "file://${config.sops.secrets."authentik/secret-key".path}";
      AUTHENTIK_LOG_LEVEL = cfg.logLevel;

      AUTHENTIK_EMAIL__HOST = "file://${config.sops.secrets."authentik/smtp/host".path}";
      AUTHENTIK_EMAIL__PORT = "file://${config.sops.secrets."authentik/smtp/port".path}";
      AUTHENTIK_EMAIL__USERNAME = "file://${config.sops.secrets."authentik/smtp/username".path}";
      AUTHENTIK_EMAIL__PASSWORD = "file://${config.sops.secrets."authentik/smtp/password".path}";
      AUTHENTIK_EMAIL__USE_TLS = lib.trivial.boolToString (cfg.email.security == "tls");
      AUTHENTIK_EMAIL__USE_SSL = lib.trivial.boolToString (cfg.email.security == "starttls");
      AUTHENTIK_EMAIL__TIMEOUT = builtins.toString cfg.email.timeout;
      AUTHENTIK_EMAIL__FROM =
        if cfg.email.from.name != null
        then "${cfg.email.from.name} <${cfg.email.from.address}>"
        else cfg.email.from.address;
      AUTHENTIK_EMAIL__TEMPLATE_DIR = ./emails;
    }
    (lib.attrsets.optionalAttrs (cfg.geoip.accountId != null) (let
      directory = config.services.geoipupdate.settings.DatabaseDirectory;
    in {
      AUTHENTIK_EVENTS__CONTEXT_PROCESSORS__GEOIP = "${directory}/GeoLite2-City.mmdb";
      AUTHENTIK_EVENTS__CONTEXT_PROCESSORS__ASN = "${directory}/GeoLite2-ASN.mmdb";
    }))
    (lib.attrsets.optionalAttrs (cfg.media.backend == "file") {
      AUTHENTIK_STORAGE__MEDIA__BACKEND = "file";
      AUTHENTIK_STORAGE__MEDIA__FILE__PATH = cfg.media.path;
    })
    (lib.attrsets.optionalAttrs (cfg.media.backend == "s3") {
      AUTHENTIK_STORAGE__MEDIA__BACKEND = "s3";
      AUTHENTIK_STORAGE__MEDIA__S3__BUCKET_NAME = cfg.media.s3.bucket;
      AUTHENTIK_STORAGE__MEDIA__S3__REGION = cfg.media.s3.region;
      AUTHENTIK_STORAGE__MEDIA__S3__ENDPOINT = lib.mkIf (cfg.media.s3.endpoint != null) cfg.media.s3.endpoint;
      AUTHENTIK_STORAGE__MEDIA__S3__ACCESS_KEY = lib.mkIf (cfg.media.s3.accessKey != null) "file://${config.sops.secrets."authentik/media/s3/access-key".path}";
      AUTHENTIK_STORAGE__MEDIA__S3__SECRET_KEY = lib.mkIf (cfg.media.s3.secretKey != null) "file://${config.sops.secrets."authentik/media/s3/secret-key".path}";
    })
  ];
in {
  imports = [./ldap.nix ./proxy.nix];

  options.components.authentik = {
    enable = lib.mkEnableOption "Enable the Authentik component";
    sopsFile = extra.mkSecretSourceOption config;

    domain = lib.mkOption {
      type = lib.types.str;
      example = "idp.example.com";
      description = "The domain to use for the Authentik instance";
    };

    secretKey = extra.mkSecretOption "secret key for cookie signing" "authentik/secret_key";

    logLevel = lib.mkOption {
      type = lib.types.enum ["debug" "info" "warning" "error"];
      default = "info";
      example = "info";
      description = ''
        The log level to use for the Authentik instance.
        Possible values are: debug, info, warning, error.
      '';
    };

    geoip = {
      accountId = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        example = 20001;
        description = "Your MaxMind account ID.";
      };

      licenseKey = extra.mkSecretOption "license key for MaxMind" "geoip/license_key";
    };

    media = {
      backend = lib.mkOption {
        type = lib.types.enum ["file" "s3"];
        default = "file";
        example = "file";
        description = "Where to store files";
      };

      path = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/authentik/media";
        example = "/var/lib/authentik/media";
        description = ''
          The path to use for the media backend. Only used if the media backend is set to `file`.
          This path must be writable by the authentik user.
        '';
      };

      s3 = {
        endpoint = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          example = "https://s3.ca-central-1.amazonaws.com";
          description = ''
            The provider's S3 endpoint URL. Only used if the media backend is set to `s3`.
          '';
          default = null;
        };

        bucket = lib.mkOption {
          type = lib.types.str;
          example = "authentik";
          description = ''
            The S3 bucket to use for the media backend. Only used if the media backend is set to `s3`.
          '';
        };

        region = lib.mkOption {
          type = lib.types.str;
          example = "us-east-1";
          description = ''
            The S3 region where the bucket was created. Only used if the media backend is set to `s3`.
          '';
        };

        accessKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          example = "authentik/s3/access-key";
          default = null;
          description = ''
            The key used to lookup the provider's access key ID secret in the SOPS file. Only used if the media backend is set to `s3`.
          '';
        };
        secretKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          example = "authentik/s3/secret-key";
          default = null;
          description = ''
            The key used to lookup the provider's secret access key secret in the SOPS file. Only used if the media backend is set to `s3`.
          '';
        };
      };
    };

    sessions = {
      storage = lib.mkOption {
        type = lib.types.enum ["cache" "db"];
        default = "cache";
        example = "cache";
        description = "The session storage backend to use for the Authentik instance.";
      };

      unauthenticatedAge = lib.mkOption {
        type = lib.types.str;
        default = "days=1";
        description = ''
          Configure how long unauthenticated sessions last for. Does not impact how long
          authenticated sessions are valid for.

          Formatted as a string in the form `hours=1;minutes=3;seconds=5`. Valid units are
          `microseconds`, `milliseconds`, `seconds`, `minutes`, `hours`, `days`, and `weeks`.
        '';
      };
    };

    email = {
      host = extra.mkSecretOption "hostname of the SMTP server" "authentik/smtp/host";
      port = extra.mkSecretOption "port of the SMTP server" "authentik/smtp/port";
      username = extra.mkSecretOption "username for the SMTP server" "authentik/smtp/username";
      password = extra.mkSecretOption "password for the SMTP server" "authentik/smtp/password";

      security = lib.mkOption {
        type = lib.types.enum ["none" "starttls" "tls"];
        default = "starttls";
        example = "starttls";
        description = ''
          The security method to use for the SMTP server. `none` means no security,
          `starttls` uses implicit TLS, and `tls` uses explicit TLS.
        '';
      };

      timeout = lib.mkOption {
        type = lib.types.int;
        default = 30;
        example = 30;
        description = "The timeout for the SMTP server in seconds";
      };

      from = {
        name = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "Authentik";
          description = "The name to use for the sender of the email";
        };
        address = lib.mkOption {
          type = lib.types.str;
          default = "no-reply@${cfg.domain}";
          description = "The email address to use for the sender of the email";
        };
      };
    };

    web = {
      listeners = {
        http = lib.mkOption {
          type = lib.types.str;
          default = "[::1]:9000";
          description = "The address to listen on for HTTP connections";
        };

        https = lib.mkOption {
          type = lib.types.str;
          default = "[::1]:9443";
          description = "The address to listen on for HTTPS connections";
        };
      };

      path = lib.mkOption {
        type = lib.types.str;
        default = "/";
        example = "/authentik/";
        description = ''
          Configure the path under which authentik is serverd. For example to access authentik
          under https://my.domain/authentik/, set this to /authentik/. Value must contain both
          a leading and trailing slash.
        '';
      };

      workers = lib.mkOption {
        type = lib.types.int;
        default = 2;
        example = 2;
        description = "Configure how many gunicorn worker processes should be started";
      };

      threads = lib.mkOption {
        type = lib.types.int;
        default = 4;
        example = 4;
        description = "Configure how many gunicorn threads a worker processes should have";
      };
    };

    worker = {
      concurrency = lib.mkOption {
        type = lib.types.int;
        default = 2;
        example = 2;
        description = ''
          Configure Celery worker concurrency for authentik worker. This essentially defines the
          number of worker processes spawned for a single worker.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.redis.servers.authentik.enable = true;
    components.database.databases = [database];

    services.geoipupdate = lib.mkIf (cfg.geoip.accountId != null) {
      enable = true;
      settings = {
        AccountID = cfg.geoip.accountId;
        LicenseKey._secret = config.sops.secrets."geoip/license-key".path;
        EditionIDs = ["GeoLite2-City" "GeoLite2-ASN"];
      };
    };

    systemd.services = {
      authentik-web = {
        description = "Authentik identity provider server";
        after = ["network.target" "postgresql.service" "redis.service"];
        wants = ["postgresql.service" "redis.service"];
        wantedBy = ["multi-user.target"];

        environment =
          commonEnvironment
          // {
            AUTHENTIK_LISTEN__HTTP = cfg.web.listeners.http;
            AUTHENTIK_LISTEN__HTTPS = cfg.web.listeners.https;

            AUTHENTIK_COOKIE_DOMAIN = cfg.domain;

            AUTHENTIK_SESSION_STORAGE = cfg.sessions.storage;
            AUTHENTIK_SESSIONS__UNAUTHENTICATED_AGE = cfg.sessions.unauthenticatedAge;

            AUTHENTIK_WEB__WORKERS = builtins.toString cfg.web.workers;
            AUTHENTIK_WEB__THREADS = builtins.toString cfg.web.threads;
            AUTHENTIK_WEB__PATH = cfg.web.path;
          };

        serviceConfig = {
          Type = "simple";
          User = "authentik";
          Group = "authentik";
          ExecStart = "${pkg}/bin/ak server";

          Restart = "on-failure";
          RestartSec = "5s";

          StateDirectory = "authentik";
          RuntimeDirectory = "authentik";
        };

        unitConfig = {
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
      };

      authentik-worker = {
        description = "Authentik identity provider worker";
        after = ["network.target" "postgresql.service" "redis.service"];
        wants = ["postgresql.service" "redis.service"];
        wantedBy = ["multi-user.target"];

        environment =
          commonEnvironment
          // {
            AUTHENTIK_WORKER__CONCURRENCY = builtins.toString cfg.worker.concurrency;
          };

        serviceConfig = {
          Type = "simple";
          User = "authentik";
          Group = "authentik";
          ExecStart = "${pkg}/bin/ak worker";

          Restart = "on-failure";
          RestartSec = "5s";

          StateDirectory = "authentik";
          RuntimeDirectory = "authentik";
        };

        unitConfig = {
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
      };
    };

    systemd.tmpfiles.settings = lib.mkIf (cfg.media.backend == "file") {
      "10-authentik".${cfg.media.path}.d = {
        age = "-";
        mode = "0755";
        user = config.users.users.authentik.name;
        group = config.users.groups.authentik.name;
      };
    };

    components.reverseProxy = {
      backends.authentik.servers = [cfg.web.listeners.http];
      hosts.${cfg.domain}.locations.${cfg.web.path} = {
        proxyTo = "http://authentik";
        proxyWebsockets = true;
      };
    };

    users = {
      users.authentik = {
        isSystemUser = true;
        group = config.users.groups.authentik.name;
        extraGroups = [config.services.redis.servers.authentik.group];
      };
      groups.authentik = {};
    };

    sops.secrets = let
      instance = key: {
        inherit key;
        inherit (cfg) sopsFile;

        owner = config.users.users.authentik.name;
        group = config.users.groups.authentik.name;

        restartUnits = with config.systemd.services; [authentik-web.name authentik-worker.name];
      };
    in {
      "authentik/secret-key" = instance cfg.secretKey;
      "authentik/smtp/host" = instance cfg.email.host;
      "authentik/smtp/port" = instance cfg.email.port;
      "authentik/smtp/username" = instance cfg.email.username;
      "authentik/smtp/password" = instance cfg.email.password;
      "authentik/media/s3/access-key" = lib.mkIf (cfg.media.s3.accessKey != null) (instance cfg.media.s3.accessKey);
      "authentik/media/s3/secret-key" = lib.mkIf (cfg.media.s3.secretKey != null) (instance cfg.media.s3.secretKey);
      "geoip/license-key" = lib.mkIf (cfg.geoip.accountId != null) (instance cfg.geoip.licenseKey);
    };
  };
}
