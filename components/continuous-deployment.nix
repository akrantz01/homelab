{
  config,
  lib,
  host,
  ...
}: let
  cfg = config.components.continuousDeployment;
in {
  options.components.continuousDeployment = {
    enable = lib.mkEnableOption "Enable continuous deployment through Garnix";

    frequency = lib.mkOption {
      type = lib.types.str;
      default = "minutely";
      description = "The frequency at which to check for updates.";
    };
  };

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      flake = "github:akrantz01/homelab#${host.hostname}";

      dates = cfg.frequency;
      flags = [
        "--option"
        "accept-flake-config"
        "true"

        "--option"
        "tarball-ttl"
        "0"
      ];
    };
  };
}
