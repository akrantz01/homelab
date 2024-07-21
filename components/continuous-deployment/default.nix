{ config, lib, host, ... }:

let
  cfg = config.components.continuousDeployment;
in
{
  options.components.continuousDeployment.enable = lib.mkEnableOption "Enable continuous deployment through Garnix";

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      flake = "github:akrantz01/homelab#${host.hostname}";

      dates = "minutely";
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
