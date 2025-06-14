{modulesPath, ...}: {
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  ec2.efi = true;
  time.timeZone = "America/Montreal";

  environment.etc."homelab/initialized".text = "";

  components = {
    continuousDeployment = {
      enable = true;
      frequency = "*:0/10"; # every 10 minutes
    };

    reverseProxy.enable = true;
    database.enable = true;

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
          bucket = "login-krantz-dev-media-20250527043344039500000001";
          region = "ca-central-1";
        };
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
