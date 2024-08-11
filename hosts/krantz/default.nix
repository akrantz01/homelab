{
  extra,
  host,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  time.timeZone = "America/New_York";

  components = {
    continuousDeployment.enable = true;
    sshTunnel.enable = true;
    vpn = {
      enable = true;
      addresses = ["10.2.0.2"];
      dns = ["10.2.0.1"];
      peers = [
        {
          # ProtonVPN US-IL#257
          publicKey = "houxrsE+RottYWy4pSsRM8ZEReqN0cEzPGtYOzmjOF0=";
          endpoint = "89.187.180.27:51820";
        }
      ];
    };

    reverseProxy = {
      enable = true;
      defaultListenAddresses = ["23.139.82.37" "[2602:fb89:1:25::37:1]"];
    };
    database.enable = true;
    authentication = {
      enable = true;
      domain = "login.krantz.dev";

      passwordResetUrl = "https://console.jumpcloud.com/login?template=resetUserPassword";

      sopsFile = extra.currentHostSecrets host "authentication.yaml";
      secrets = {
        jwt = "secrets/jwt";
        session = "secrets/session";
        storage = "secrets/storage";
      };

      ldap = {
        implementation = "custom";
        address = "ldap/address";
        baseDN = "ldap/base_dn";
        user = "ldap/bind/user";
        password = "ldap/bind/password";
      };

      smtp = {
        address = "notifier/address";
        username = "notifier/username";
        password = "notifier/password";
      };
    };
    backblaze = {
      enable = true;
      buckets.watch-krantz-dev = {
        chunked = true;
        paths = {
          "/mnt/movies" = "movies";
          "/mnt/tv" = "tv";
        };
      };
    };

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

    streaming = {
      enable = true;
      domain = "watch.krantz.dev";
      listenAddresses = ["23.139.82.253" "[2602:fb89:1:25::253:1]"];
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
