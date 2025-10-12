{
  config,
  extra,
  lib,
  host,
  pkgs-stable,
  ...
}: let
  cfg = config.components.database;

  services = lib.flatten (
    lib.mapAttrsToList (
      stanza: {jobs, ...}:
        lib.map (job: "pgbackrest-${stanza}-${job}") (lib.attrNames jobs)
    )
    config.services.pgbackrest.stanzas
  );

  hasBackupKeys = cfg.backups.enable && cfg.backups.accessKey != null;

  logPath = "/var/log/pgbackrest";
in {
  options.components.database = {
    enable = lib.mkEnableOption "Enable the database component";
    sopsFile = extra.mkSecretSourceOption config;

    databases = lib.mkOption {
      default = [];
      type = lib.types.listOf lib.types.str;
      description = "List of databases and their corresponding users to create";
    };

    backups = {
      enable = lib.mkEnableOption "Enable database backups";

      bucket = lib.mkOption {
        type = lib.types.str;
        description = "The backblaze b2 bucket to upload to";
      };

      region = lib.mkOption {
        type = lib.types.str;
        description = "The region where the bucket was created";
      };

      endpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        example = "s3.ca-central-1.amazonaws.com";
        description = ''
          The provider's S3 endpoint URL.
        '';
        default = null;
      };

      accessKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        example = "database/backup/access-key";
        default = null;
        description = ''
          The key used to lookup the provider's access key ID secret in the SOPS file.
        '';
      };
      secretKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        example = "database/backup/secret-key";
        default = null;
        description = ''
          The key used to lookup the provider's secret access key secret in the SOPS file.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = pkgs-stable.postgresql_16;

      enableJIT = true;
      enableTCPIP = false;

      ensureDatabases = cfg.databases;
      ensureUsers =
        builtins.map (db: {
          name = db;
          ensureDBOwnership = true;
        })
        cfg.databases;
    };

    services.pgbackrest = lib.mkIf cfg.backups.enable {
      enable = true;

      settings = {
        log-level-console = "info";
        log-level-file = "info";
        log-path = logPath;
        log-timestamp = true;

        process-max = 4;
        archive-async = false;

        compress-type = "zst";

        start-fast = true;
      };

      repos.b2 = {
        type = "s3";
        path = "/postgres/${host.hostname}";
        s3-bucket = cfg.backups.bucket;
        s3-endpoint = lib.mkIf (cfg.backups.endpoint != null) cfg.backups.endpoint;
        s3-region = cfg.backups.region;
        s3-uri-style = "path";
        s3-key-type =
          if hasBackupKeys
          then "shared"
          else "auto";

        cipher-type = "none";

        retention-full = 3;
        retention-diff = 7;
        retention-archive = 3;
        retention-archive-type = "full";
        retention-history = 7;

        bundle = true;
        block = true;
      };

      stanzas.default.jobs = {
        full = {
          schedule = "Sun 02:00";
          type = "full";
        };

        diff = {
          schedule = "daily";
          type = "diff";
        };
      };
    };

    sops = let
      ownership = {
        owner = config.users.users.pgbackrest.name;
        group = config.users.users.postgres.group;
        mode = "0440";
      };
    in
      lib.mkIf hasBackupKeys {
        secrets = let
          instance = key: ({
              inherit key;
              inherit (cfg) sopsFile;
            }
            // ownership);
        in {
          "pgbackrest/backblaze-id" = instance cfg.backups.accessKey;
          "pgbackrest/backblaze-key" = instance cfg.backups.secretKey;
        };

        templates."pgbackrest.env" =
          {
            content = ''
              PGBACKREST_REPO1_S3_KEY=${config.sops.placeholder."pgbackrest/backblaze-id"}
              PGBACKREST_REPO1_S3_KEY_SECRET=${config.sops.placeholder."pgbackrest/backblaze-key"}
            '';

            reloadUnits = [config.systemd.services.postgresql.name] ++ lib.map (service: config.systemd.services.${service}.name) services;
          }
          // ownership;
      };

    systemd = lib.mkIf cfg.backups.enable {
      services = lib.mkIf hasBackupKeys ((
          lib.listToAttrs (
            lib.map (service: {
              name = service;
              value.serviceConfig.EnvironmentFile = config.sops.templates."pgbackrest.env".path;
            })
            services
          )
        )
        // {
          postgresql.serviceConfig.EnvironmentFile = config.sops.templates."pgbackrest.env".path;
        });

      tmpfiles.settings."10-pgbackrest".${logPath}.d = {
        age = "-";
        mode = "0770";
        user = config.users.users.pgbackrest.name;
        group = config.users.users.postgres.group;
      };
    };
  };
}
