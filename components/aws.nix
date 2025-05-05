{
  config,
  lib,
  ...
}: let
  cfg = config.components.aws;
in {
  options.components.aws = {
    enable = lib.mkEnableOption "Enable the AWS component";

    url = lib.mkOption {
      type = lib.types.str;
      description = "The URL of the Tailfed API";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailfed = {
      enable = true;
      url = cfg.url;
    };
  };
}
