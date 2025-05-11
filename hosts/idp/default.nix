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

      email = {
        security = "tls";
        from.name = "Login";
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
