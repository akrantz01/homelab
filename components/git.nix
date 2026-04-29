{
  config,
  extra,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.git;
in {
  options.components.git = {
    enable = lib.mkEnableOption "Enable the Git forge component";
    sopsFile = extra.mkSecretSourceOption config;

    domain = lib.mkOption {
      type = lib.types.str;
      example = "git.example.com";
      description = "The domain to use for the Forgejo instance";
    };
  };

  config = lib.mkIf cfg.enable {
    services.forgejo = {
      enable = true;
      package = pkgs-unstable.forgejo;

      database = {
        type = "postgres";
        createDatabase = true;
      };

      lfs.enable = true;

      settings = {
        server = {
          PROTOCOL = "http+unix";
          DOMAIN = cfg.domain;
          ROOT_URL = "https://${cfg.domain}";
        };

        session.COOKIE_SECURE = true;

        repository = {
          DEFAULT_REPO_UNITS = lib.concatStringsSep "," ["repo.code" "repo.issues" "repo.pulls" "repo.actions"];
          DEFAULT_FORK_REPO_UNITS = lib.concatStringsSep "," ["repo.code" "repo.issues"];
          DEFAULT_MIRROR_REPO_UNITS = lib.concatStringsSep "," ["repo.code" "repo.issues"];

          DEFAULT_BRANCH = "main";
        };
        "repository.pull-request" = {
          DEFAULT_MERGE_STYLE = "rebase";
          DEFAULT_UPDATE_STYLE = "rebase";
        };

        markdown = {
          CUSTOM_URL_SCHEMES = "http,https";
        };

        service = {
          ENABLE_INTERNAL_SIGNIN = true;
          DISABLE_REGISTRATION = false;

          ENABLE_BASIC_AUTHENTICATION = false;
        };
      };
    };

    components.reverseProxy = {
      backends.forgejo.servers = ["unix:${config.services.forgejo.settings.server.HTTP_ADDR}"];
      hosts.${cfg.domain} = {
        extraConfig = ''
          client_max_body_size 512M;
          merge_slashes off;
        '';

        locations."/" = {
          proxyTo = "http://forgejo";
          proxyWebsockets = true;
        };
      };
    };
  };
}
