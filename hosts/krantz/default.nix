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
    vpn = {
      enable = true;
      addresses = ["10.2.0.2"];
      dns = ["1.1.1.1" "1.0.0.1"];
      peer = {
        # ProtonVPN US-NY#533
        publicKey = "Q+F33KqUr9obW0a7u9ZwNRrQlcwcoNdStZfTs321CTY=";
        endpoint = "146.70.202.98:51820";
      };
    };

    reverseProxy = {
      enable = true;
      defaultListenAddresses = ["23.139.82.37" "[2602:fb89:1:25::37:1]"];
    };
    database = {
      enable = true;
      backups.enable = true;
    };
    authentication = {
      # Disabled in favor of Cloudflare Zero Trust
      enable = false;
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
        from.address = "no-reply@krantz.dev";
      };
    };
    aws = {
      enable = true;
      url = "https://tailfed.krantz.cloud";
    };
    backblaze = {
      enable = true;
      buckets = {
        watch-krantz-dev = {
          chunked = true;
          paths = {
            "/mnt/movies" = "movies";
            "/mnt/tv" = "tv";
          };
        };
        primary-krantz-dev-backups.paths."/mnt/backups/postgres" = "postgres";
      };
    };

    authentik = {
      domain = "login.krantz.dev";
      ldap.enable = true;
      proxy.enable = true;
    };

    atuin = {
      enable = true;
      domain = "shell.krantz.dev";
    };
    mealie = {
      enable = true;
      domain = "recipes.krantz.dev";

      oidc = {
        enable = true;
        provider = "krantz.dev";
        configurationUrl = "https://login.krantz.dev/application/o/recipes/.well-known/openid-configuration";
        clientId = "PoMS5Wm9tRrzILgTHEkrmYsHEyZmSsPYee2ImzVb";

        # TODO: update once groups are established; same for groups.admin
        groups.user = "authentik Users";
      };
      smtp = {
        enable = true;
        from.address = "no-reply@krantz.dev";
      };
    };
    miniflux = {
      enable = true;
      domain = "rss.krantz.dev";

      oauth2 = {
        provider = "oidc";
        discoveryEndpoint = "https://login.krantz.dev/application/o/rss/";
      };
    };
    vaultwarden = {
      enable = true;
      domain = "vault.krantz.dev";
      admin = {
        enable = true;
        authMethod = "proxy";
      };
      pushNotifications.enable = true;
      smtp = {
        enable = true;
        from.address = "no-reply@krantz.dev";
      };
    };

    streaming = {
      enable = true;
      domain = "watch.krantz.dev";
      listenAddresses = ["23.139.82.253" "[2602:fb89:1:25::253:1]"];
    };
    torrent = {
      enable = true;
      domain = "torrent.krantz.cloud";
      proxyAuth = true;
    };
    pvr = {
      enable = true;
      baseDomain = "krantz.cloud";
      domains = {
        jellyseerr.name = "media.krantz.dev";
        bazarr.proxyAuth = true;
        radarr.proxyAuth = true;
        sonarr.proxyAuth = true;
        prowlarr.proxyAuth = true;
      };
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
