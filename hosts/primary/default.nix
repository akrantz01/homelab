{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  time.timeZone = "America/Montreal";

  components = {
    continuousDeployment.enable = true;
    #   vpn = {
    #     enable = true;
    #     addresses = ["10.2.0.2" "2a07:b944::2:2"];
    #     dns = ["1.1.1.1" "1.0.0.1"];
    #     peer = {
    #       # ProtonVPN US-NY#533
    #       publicKey = "Q+F33KqUr9obW0a7u9ZwNRrQlcwcoNdStZfTs321CTY=";
    #       endpoint = "146.70.202.98:51820";
    #     };
    #   };

    reverseProxy = {
      enable = true;
      defaultListenAddresses = ["149.56.241.57" "[2607:5300:61:1039::57:1]"];
    };
    database = {
      enable = true;
      backups = {
        enable = true;
        restoreFrom = "krantz";
        endpoint = "s3.us-east-005.backblazeb2.com";
        bucket = "krantz-cloud-backups";
        region = "us-east-005";
        accessKey = "backblaze/backups/id";
        secretKey = "backblaze/backups/key";
      };
    };
    aws = {
      enable = true;
      url = "https://tailfed.krantz.cloud";
    };
    backblaze = {
      enable = true;
      credentials.watch = {
        id = "backblaze/watch/id";
        key = "backblaze/watch/key";
      };
      buckets.watch-krantz-dev = {
        credential = "watch";
        chunked = true;
        paths = {
          "/srv/movies" = "movies";
          "/srv/tv" = "tv";
        };
      };
    };
    meilisearch.enable = true;

    authentik = {
      domain = "login.krantz.dev";
      ldap.enable = true;
      proxy.enable = true;
    };

    #   atuin = {
    #     enable = true;
    #     domain = "shell.krantz.dev";
    #   };
    #   karakeep = {
    #     enable = true;
    #     domain = "links.krantz.dev";

    #     ai.autoTagging = true;
    #     oauth = {
    #       enable = true;
    #       name = "krantz.dev";
    #       discoveryEndpoint = "https://login.krantz.dev/application/o/karakeep/.well-known/openid-configuration";
    #     };
    #     smtp = {
    #       enable = true;
    #       from.address = "no-reply@krantz.dev";
    #     };
    #   };
    #   mealie = {
    #     enable = true;
    #     domain = "recipes.krantz.dev";

    #     oidc = {
    #       enable = true;
    #       provider = "krantz.dev";
    #       configurationUrl = "https://login.krantz.dev/application/o/recipes/.well-known/openid-configuration";
    #       clientId = "PoMS5Wm9tRrzILgTHEkrmYsHEyZmSsPYee2ImzVb";

    #       # TODO: update once groups are established; same for groups.admin
    #       groups.user = "authentik Users";
    #     };
    #     smtp = {
    #       enable = true;
    #       from.address = "no-reply@krantz.dev";
    #     };
    #   };
    #   miniflux = {
    #     enable = true;
    #     domain = "rss.krantz.dev";

    #     oauth2 = {
    #       provider = "oidc";
    #       discoveryEndpoint = "https://login.krantz.dev/application/o/rss/";
    #     };
    #   };
    #   vaultwarden = {
    #     enable = true;
    #     domain = "vault.krantz.dev";
    #     admin = {
    #       enable = true;
    #       authMethod = "proxy";
    #     };
    #     pushNotifications.enable = true;
    #     smtp = {
    #       enable = true;
    #       from.address = "no-reply@krantz.dev";
    #     };
    #   };
    #   workflows = {
    #     enable = true;
    #     domain = "workflows.krantz.cloud";
    #     email = {
    #       security = "tls";
    #       from.address = "no-reply@krantz.dev";
    #     };
    #     oidc = {
    #       enabled = true;
    #       discoveryEndpoint = "https://login.krantz.dev/application/o/workflows/";
    #     };
    #   };

    #   streaming = {
    #     enable = true;
    #     domain = "watch.krantz.dev";
    #     listenAddresses = ["51.79.11.112" "[2607:5300:61:1039::112:1]"];
    #   };
    #   torrent = {
    #     enable = true;
    #     domain = "torrent.krantz.cloud";
    #     proxyAuth = true;
    #     paths = {
    #       complete = "/srv/torrents/complete";
    #       incomplete = "/srv/torrents/incomplete";
    #     };
    #   };
    #   pvr = {
    #     enable = true;
    #     baseDomain = "krantz.cloud";
    #     domains = {
    #       jellyseerr.name = "media.krantz.dev";
    #       bazarr.proxyAuth = true;
    #       radarr.proxyAuth = true;
    #       sonarr.proxyAuth = true;
    #       prowlarr.proxyAuth = true;
    #     };
    #   };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
