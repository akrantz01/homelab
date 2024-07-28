{lib, ...}: {
  mkSecretOption = description: key:
    lib.mkOption {
      type = lib.types.str;
      default = key;
      description = "The key used to lookup the ${description} secret in the SOPS file";
    };

  mkSecretSourceOption = config:
    lib.mkOption {
      type = lib.types.path;
      default = config.sops.defaultSopsFile;
      description = "The path to the SOPS file containing the secrets";
    };
}
