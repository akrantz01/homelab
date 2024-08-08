{
  config,
  extra,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.backblaze;

  bucketType = lib.types.submodule {
    options = {
      chunked = lib.mkEnableOption "Split large files into smaller chunks (1GB)";
      paths = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "A mapping of local paths to remote paths";
      };
    };
  };

  backend.b2 = {
    type = "b2";
    hard_delete = true;
    account = config.sops.placeholder."backblaze/id";
    key = config.sops.placeholder."backblaze/key";
  };

  bucketConfigs = lib.mapAttrs (bucket: settings:
    {remote = "b2:${bucket}";}
    // (
      if settings.chunked
      then {
        type = "chunker";
        chunk_size = "1Gi";
        hash_type = "sha1";
      }
      else {type = "alias";}
    ))
  cfg.buckets;

  flattenedMounts = lib.lists.flatten (
    lib.lists.map (
      bucket:
        lib.lists.map (mapping: {
          bucket = bucket.name;
          source = mapping.value;
          destination = mapping.name;
        }) (lib.attrsets.attrsToList bucket.value.paths)
    ) (lib.attrsets.attrsToList cfg.buckets)
  );

  pathToIdent = path: let
    segments = lib.lists.drop 1 (lib.lists.flatten (builtins.split "/" path));
  in
    builtins.concatStringsSep "-" segments;

  restartUnits = lib.lists.map (mount: "${pathToIdent mount.destination}.mount") flattenedMounts;
in {
  options.components.backblaze = {
    enable = lib.mkEnableOption "Enable the Backblaze B2 mount component";
    sopsFile = extra.mkSecretSourceOption config;

    id = extra.mkSecretOption "Backblaze account/application key ID" "backblaze/id";
    key = extra.mkSecretOption "Backblaze account/application key" "backblaze/key";

    buckets = lib.mkOption {
      type = lib.types.attrsOf bucketType;
      default = {};
      description = "A mapping of bucket names to mounts";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.lists.all (mount: lib.strings.hasPrefix "/" mount.destination) flattenedMounts;
        message = "All mount destinations must be absolute paths";
      }
    ];

    environment.systemPackages = with pkgs-unstable; [rclone];

    systemd.mounts =
      lib.lists.map (mount: {
        name = "${pathToIdent mount.destination}.mount";
        type = "rclone";
        description = "the ${mount.source} path in the ${mount.bucket} bucket at ${mount.destination}";
        what = "${mount.bucket}:${mount.source}";
        where = mount.destination;
        options = builtins.concatStringsSep "," [
          "rw"
          "_netdev"
          "allow_other"
          "args2env"
          "config=${config.sops.templates."backblaze/rclone.conf".path}"
          "cache_dir=/var/cache/rclone"
          "vfs_cache_mode=full"
          "vfs_cache_max_age=24h"
          "no_modtime"
          "transfers=8"
          "buffer_size=128Mi"
          "vfs_read_ahead=512Mi"
        ];
      })
      flattenedMounts;

    sops.secrets."backblaze/id" = {
      inherit restartUnits;
      inherit (cfg) sopsFile;
      key = cfg.id;
    };
    sops.secrets."backblaze/key" = {
      inherit restartUnits;
      inherit (cfg) sopsFile;
      key = cfg.key;
    };

    sops.templates."backblaze/rclone.conf".content = lib.generators.toINI {} (lib.attrsets.mergeAttrsList [
      backend
      bucketConfigs
    ]);
  };
}
