{
  config,
  lib,
  ...
}: let
  cfg = config.components.authelia;
in {
  options.components.authelia = {
    enable = lib.mkEnableOption "Enable the Authelia component";
  };

  config = lib.mkIf cfg.enable {
    services.authelia.instances.default = {
      enable = true;

      settings.server = {
        host = "::1";
        port = 2884;
      };

      settings.theme = "grey";
      settings.default_2fa_method = "totp";
      settings.log.level = "info";
      settings.log.format = "text";

      settings.secrets = {};
    };
  };
}
