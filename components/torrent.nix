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

      downloadDirPermissions = "760";

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

    systemd.services.flood = {
      description = "Flood web UI for Transmission";
      after = ["netowrk.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        KillMode = "process";

        ExecStart = builtins.concatStringsSep " " [
          "${pkgs-unstable.flood}/bin/flood"
          "--rundir=/var/lib/flood"
          "--auth=none"
          "--port=3563"
          "--allowedpath=${config.services.transmission.settings.download-dir}"
          "--allowedpath=${config.services.transmission.settings.incomplete-dir}"
          "--trurl=unix:///run/transmission/rpc.sock"
          "--truser=\"\""
          "--trpass=\"\""
        ];

        User = "flood";
        Group = "flood";
        DynamicUser = true;

        Restart = "on-failure";
        RestartSec = 3;

        StateDirectory = "flood";
      };
    };
  };
}
