{
  config,
  extra,
  lib,
  pkgs-stable,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.git;

  package = pkgs-unstable.forgejo;
  user = config.services.forgejo.settings.server.SSH_USER;
in {
  options.components.git = {
    enable = lib.mkEnableOption "Enable the Git forge component";
    sopsFile = extra.mkSecretSourceOption config;

    domain = lib.mkOption {
      type = lib.types.str;
      example = "git.example.com";
      description = "The domain to use for the Forgejo instance";
    };

    gitDomain = lib.mkOption {
      type = lib.types.str;
      default = cfg.domain;
      description = "The domain to use for accessing the instance via SSH";
    };

    mailer = {
      enable = lib.mkEnableOption "Enable the mailer";
      protocol = lib.mkOption {
        type = lib.types.enum ["smtp" "smtps" "smtp+starttls" "smtp+unix"];
        default = "smtp";
        description = "The protocol to use";
      };

      host = extra.mkSecretOption "hostname of the SMTP server" "git/smtp/host";
      port = extra.mkSecretOption "port of the SMTP server" "git/smtp/port";
      username = extra.mkSecretOption "username for the SMTP server" "git/smtp/username";
      password = extra.mkSecretOption "password for the SMTP server" "git/smtp/password";

      from = {
        name = lib.mkOption {
          type = lib.types.str;
          example = "Git";
          description = "The name to use for the sender of the email";
        };
        address = lib.mkOption {
          type = lib.types.str;
          default = "no-reply@${cfg.domain}";
          description = "The email address to use for the sender of the email";
        };
      };
    };

    captcha = {
      type = lib.mkOption {
        type = with lib.types; nullOr (enum ["recaptcha" "hcaptcha" "mcaptcha" "cfturnstile"]);
        default = null;
        description = "The captcha implementation to use";
      };

      sitekey = extra.mkSecretOption "captcha implementation site key" "git/captcha/sitekey";
      secret = extra.mkSecretOption "captcha implementation secret key" "git/captcha/secret";
    };
  };

  config = lib.mkIf cfg.enable {
    services.forgejo = {
      enable = true;
      inherit package;

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

          SSH_DOMAIN = cfg.gitDomain;
          SSH_USER = "git";
          SSH_CREATE_AUTHORIZED_KEYS_FILE = false;
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
        "repository.signing" = {
          DEFAULT_TRUST_MODEL = "committer";
        };

        mailer = lib.mkIf cfg.mailer.enable {
          ENABLED = true;
          PROTOCOL = cfg.mailer.protocol;
          FROM = ''"${cfg.mailer.from.name}" <${cfg.mailer.from.address}>'';
        };

        markdown = {
          CUSTOM_URL_SCHEMES = "http,https";
        };

        service = {
          ENABLE_INTERNAL_SIGNIN = false;
          DISABLE_REGISTRATION = true;

          ENABLE_BASIC_AUTHENTICATION = false;

          ENABLE_CAPTCHA = cfg.captcha.type != null;
          CAPTCHA_TYPE = lib.mkIf (cfg.captcha.type != null) cfg.captcha.type;
        };
      };

      secrets = let
        ref = key: config.sops.secrets.${key}.path;
      in {
        mailer = lib.mkIf cfg.mailer.enable {
          SMTP_ADDR = ref cfg.mailer.host;
          SMTP_PORT = ref cfg.mailer.port;
          USER = ref cfg.mailer.username;
          PASSWD = ref cfg.mailer.password;
        };

        service = lib.mkIf (cfg.captcha.type != null) (let
          key =
            if cfg.captcha.type == "cfturnstile"
            then "CF_TURNSTILE"
            else lib.strings.toUpper cfg.captcha.type;
        in {
          "${key}_SITEKEY" = ref cfg.captcha.sitekey;
          "${key}_SECRET" = ref cfg.captcha.secret;
        });
      };
    };

    users.users.${user} = {
      isSystemUser = true;
      useDefaultShell = true;
      group = user;
    };
    users.groups.${user} = {};

    environment.etc."ssh/forgejo_authorized_keys" = {
      mode = "0555";
      source = pkgs-stable.writeShellScript "authorized-keys-wrapper" ''
        ${lib.getExe package} \
            --config=/var/lib/forgejo/custom/conf/app.ini \
            keys \
            --expected=git \
            --username=%u \
            --type=%t \
            --content=%k
      '';
    };

    services.openssh = {
      enable = lib.mkForce true;
      extraConfig = lib.mkBefore ''
        Match User ${user}
          AuthorizedKeysCommand /etc/ssh/forgejo_authorized_keys
          AuthorizedKeysCommandUser ${config.services.forgejo.user}
      '';
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

    sops.secrets = let
      instance = key: {
        inherit key;
        inherit (cfg) sopsFile;

        owner = config.users.users.forgejo.name;
        group = config.users.groups.forgejo.name;

        restartUnits = [config.systemd.services.forgejo.name];
      };
    in
      lib.mergeAttrsList [
        (lib.optionalAttrs cfg.mailer.enable {
          "git/smtp/host" = instance cfg.mailer.host;
          "git/smtp/port" = instance cfg.mailer.port;
          "git/smtp/username" = instance cfg.mailer.username;
          "git/smtp/password" = instance cfg.mailer.password;
        })
        (lib.optionalAttrs (cfg.captcha.type != null) {
          "git/captcha/sitekey" = instance cfg.captcha.sitekey;
          "git/captcha/secret" = instance cfg.captcha.secret;
        })
      ];
  };
}
