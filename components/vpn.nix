{
  config,
  extra,
  lib,
  pkgs-stable,
  ...
}: let
  cfg = config.components.vpn;

  interface = "wg0";
  namespace = "vpn";
in {
  options.components.vpn = {
    enable = lib.mkEnableOption "Enable the WireGuard VPN component";
    sopsFile = extra.mkSecretSourceOption config;

    privateKey = extra.mkSecretOption "The private key for the WireGuard VPN" "vpn/private_key";

    peer = {
      publicKey = lib.mkOption {
        type = lib.types.str;
        description = "The public key of the peer";
      };

      address = lib.mkOption {
        type = lib.types.str;
        description = "The IP address of the peer";
      };

      port = lib.mkOption {
        type = lib.types.int;
        default = 51820;
        description = "The port of the peer";
      };
    };

    addresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "The address(es) of the VPN interface";
    };
    dns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "The DNS server(s) to use";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = let
      kernel = config.boot.kernelPackages;
    in
      lib.optional (lib.versionOlder kernel.kernel.version "5.6") kernel.wireguard;
    boot.kernelModules = ["wireguard"];

    environment.systemPackages = [pkgs-stable.wireguard-tools];
    environment.etc."netns/${namespace}/resolv.conf".text = builtins.concatStringsSep "\n" (lib.lists.map (server: "nameserver ${server}") cfg.dns);

    systemd.services.vpn = {
      description = "Namespaced WireGuard Tunnel";

      bindsTo = ["netns@${namespace}.service"];
      requires = ["network-online.target" "nss-lookup.target"];
      after = ["netns@${namespace}.service" "network-online.target" "nss-lookup.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = let
        endpoint = "${cfg.peer.address}:${builtins.toString cfg.peer.port}";

        grep = "${pkgs-stable.gnugrep}/bin/grep";
        ip = "${pkgs-stable.iproute2}/bin/ip";
        ping = "${pkgs-stable.inetutils}/bin/ping";
        wg = "${pkgs-stable.wireguard-tools}/bin/wg";
      in {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = let
          addresses = lib.lists.map (address: "${ip} address add ${address} dev wg0") cfg.addresses;
        in
          pkgs-stable.writers.writeBash "vpn-up" ''
            set -ex

            if ! ${ip} netns list | ${grep} -q ${namespace}; then
              echo "VPN namespace ${namespace} not found"
              exit 1
            fi

            ${ip} link add ${interface} type wireguard
            ${wg} set ${interface} \
              private-key ${config.sops.secrets."vpn/private_key".path} \
              peer ${cfg.peer.publicKey} \
                endpoint ${endpoint} \
                allowed-ips 0.0.0.0/0,::/0

            ${builtins.concatStringsSep "\n" addresses}

            ${ip} link set ${interface} up

            connection_verified=false
            for ((i=1; i<=3; i++)); do
              if ${ping} -c 1 -W 3 -I wg0 ${cfg.peer.address}; then
                connection_verified=true
                break
              fi
              sleep 1
            done

            if ! $connection_verified; then
              echo "VPN connection failed after 3 attempts"
              ${ip} link del ${interface}
              exit 1
            fi

            ${ip} link set ${interface} netns ${namespace}

            ${ip} -n ${namespace} route add default dev ${interface}
            ${ip} -n ${namespace} -6 route add default dev ${interface}
          '';

        ExecStop = pkgs-stable.writers.writeBash "vpn-down" ''
          set -ex
          ${ip} -n ${namespace} link del ${interface}
          ${ip} -n ${namespace} route del default dev ${interface}
          ${ip} -n ${namespace} -6 route del default dev ${interface}
        '';
      };
    };

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
