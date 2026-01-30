{
  lib,
  pkgs-stable,
  ...
}: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  time.timeZone = "America/Montreal";

  components = {
    continuousDeployment.enable = true;

    reverseProxy.enable = true;
    database = {
      enable = true;
      backups = {
        enable = true;
        endpoint = "s3.us-east-005.backblazeb2.com";
        bucket = "krantz-cloud-backups";
        region = "us-east-005";
        accessKey = "backblaze/backups/id";
        secretKey = "backblaze/backups/key";
      };
    };

    authentik = {
      enable = true;
      domain = "login.krantz.dev";

      geoip.accountId = 1167485;

      email = {
        security = "tls";
        from = {
          name = "krantz.dev";
          address = "no-reply@krantz.dev";
        };
      };

      media = {
        backend = "s3";
        s3 = {
          endpoint = "https://s3.us-east-005.backblazeb2.com";
          bucket = "login-krantz-dev";
          region = "us-east-005";
          accessKey = "backblaze/authentik/id";
          secretKey = "backblaze/authentik/key";
        };
      };
    };
  };

  systemd.services = builtins.listToAttrs (lib.map (service: lib.nameValuePair service {enable = false;}) ["authentik-web" "authentik-worker"]);

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
