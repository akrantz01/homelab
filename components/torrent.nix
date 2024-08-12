{
  config,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.torrent;
in {
  options.components.torrent = {
    enable = lib.mkEnableOption "Enable the torrenting component";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.components.vpn.enable;
        message = "The VPN component must be enabled to use the torrenting component";
      }
    ];

    services.transmission = {
      enable = true;
      package = pkgs-unstable.transmission_4;

      settings = {
        rpc-bind-address = "unix:/run/transmission/rpc.sock";

        download-dir = "${config.services.transmission.home}/complete";

        incomplete-dir-enabled = true;
        incomplete-dir = "${config.services.transmission.home}/incomplete";
      };
    };

    systemd.services.transmission = {
      bindsTo = ["vpn.service"];
      after = ["vpn.service"];
      unitConfig.JoinsNamespaceOf = "netns@vpn.service";
      serviceConfig.PrivateNetwork = true;
    };
  };
}
