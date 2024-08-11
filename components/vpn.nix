{
  config,
  extra,
  lib,
  pkgs-stable,
  ...
}: let
  cfg = config.components.vpn;

  peerType = lib.types.submodule {
    options = {
      publicKey = lib.mkOption {
        type = lib.types.str;
        description = "The public key of the peer";
      };

      endpoint = lib.mkOption {
        type = lib.types.str;
        description = "The endpoint of the peer";
      };

      allowedIPs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["0.0.0.0/0" "::/0"];
        description = "The IP address ranges to forward to the peer";
      };
    };
  };

  interface = "wg0";
  namespace = "vpn";
in {
  options.components.vpn = {
    enable = lib.mkEnableOption "Enable the WireGuard VPN component";
    sopsFile = extra.mkSecretSourceOption config;

    privateKey = extra.mkSecretOption "The private key for the WireGuard VPN" "vpn/private_key";

    peers = lib.mkOption {
      type = lib.types.listOf peerType;
      default = [];
      description = "The peers to connect to";
    };

    addresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "The address(es) of the VPN interface";
    };
    dns = lib.mkOption {
      type = lib.types.str;
      description = "The DNS server to use";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.lists.length cfg.peers > 0;
        message = "At least VPN one peer must be configured";
      }
    ];

    sops.secrets."vpn/private_key" = {
      inherit (cfg) sopsFile;
      key = cfg.privateKey;

      owner = "root";
      group = "systemd-network";
      mode = "0640";

      reloadUnits = ["systemd-networkd.service"];
    };
  };
}
