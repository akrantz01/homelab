{
  config,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.sshTunnel;
in {
  options.components.sshTunnel = {
    enable = lib.mkEnableOption "Enable the SSH component";

    credentials = {
      key = lib.mkOption {
        type = lib.types.str;
        default = "ssh-tunnel/credentials";
        description = "The key pointing to the cloudflared tunnel credentials.";
      };
      file = lib.mkOption {
        type = lib.types.path;
        default = config.sops.defaultSopsFile;
        description = "The path to the SOPS file containing the key.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.cloudflared-tunnel-ssh = {
      after = ["network.target" "network-online.target"];
      wants = ["network.target" "network-online.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        User = config.users.users.cloudflared.name;
        Group = config.users.users.cloudflared.group;
        Restart = "on-failure";
        ExecStart = "${pkgs-unstable.cloudflared}/bin/cloudflared --no-autoupdate tunnel run";
        EnvironmentFile = config.sops.templates."cloudflared-tunnel-ssh.env".path;
      };
    };

    users.users.cloudflared = {
      group = config.users.groups.cloudflared.name;
      isSystemUser = true;
    };
    users.groups.cloudflared = {};

    sops.secrets."ssh-tunnel/credentials" = {
      key = cfg.credentials.key;
      sopsFile = cfg.credentials.file;

      owner = config.users.users.cloudflared.name;
      group = config.users.users.cloudflared.group;

      restartUnits = [config.systemd.services.cloudflared-tunnel-ssh.name];
    };

    sops.templates."cloudflared-tunnel-ssh.env" = {
      content = ''
        TUNNEL_TOKEN=${config.sops.placeholder."ssh-tunnel/credentials"}
      '';

      owner = config.users.users.cloudflared.name;
      group = config.users.users.cloudflared.group;
    };
  };
}
