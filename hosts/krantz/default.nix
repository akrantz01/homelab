{...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  time.timeZone = "America/New_York";

  components = {
    continuousDeployment.enable = true;
    sshTunnel.enable = true;

    reverseProxy.enable = true;
    database.enable = true;

    atuin = {
      enable = true;
      domain = "shell.krantz.dev";
    };
    mealie = {
      enable = false;
      domain = "recipes.krantz.dev";
    };
    miniflux = {
      enable = true;
      domain = "rss.krantz.dev";

      oauth2 = {
        provider = "oidc";
        discoveryEndpoint = "https://oauth.id.jumpcloud.com/";
      };
    };
    vaultwarden = {
      enable = true;
      domain = "vault.krantz.dev";
      admin.enable = false;
      pushNotifications.enable = true;
      smtp.enable = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
