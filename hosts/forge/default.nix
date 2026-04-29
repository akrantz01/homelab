{pkgs-stable, ...}: {
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
      package = pkgs-stable.postgresql_18;
      backups = {
        enable = true;
        endpoint = "s3.us-east-005.backblazeb2.com";
        bucket = "krantz-cloud-backups";
        region = "us-east-005";
        accessKey = "backblaze/backups/id";
        secretKey = "backblaze/backups/key";
      };
    };

    git = {
      enable = true;
      domain = "krantz.codes";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
