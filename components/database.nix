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

  spoolPath = "/var/spool/pgbackrest";
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
        log-timestamp = true;

        process-max = 4;
        archive-async = true;
        spool-path = spoolPath;

        compress-type = "zst";

        start-fast = true;
      };

      repos.b2 = {
        type = "s3";
        path = "/postgres/${host.hostname}";
        s3-bucket = cfg.backups.bucket;
        s3-endpoint = "s3.${cfg.backups.region}.backblazeb2.com";
        s3-region = cfg.backups.region;
        s3-uri-style = "path";

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

    sops.secrets = lib.mkIf cfg.backups.enable {
      "pgbackrest/backblaze-id".key = "backblaze/id";
      "pgbackrest/backblaze-key".key = "backblaze/key";
    };

    sops.templates."pgbackrest.env" = lib.mkIf cfg.backups.enable {
      content = ''
        PGBACKREST_REPO1_S3_KEY=${config.sops.placeholder."pgbackrest/backblaze-id"}
        PGBACKREST_REPO1_S3_KEY_SECRET=${config.sops.placeholder."pgbackrest/backblaze-key"}
      '';

      owner = config.users.users.pgbackrest.name;
      group = config.users.users.postgres.group;
      mode = "0440";

      reloadUnits = [config.systemd.services.postgresql.name] ++ lib.map (service: config.systemd.services.${service}.name) services;
    };

    systemd = lib.mkIf cfg.backups.enable {
      services =
        (
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
        };

      tmpfiles.settings."10-pgbackrest".${spoolPath}.d = {
        age = "-";
        mode = "0750";
        user = config.users.users.pgbackrest.name;
        group = config.users.users.pgbackrest.group;
      };
    };
  };
}
