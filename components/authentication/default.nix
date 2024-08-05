{
  config,
  extra,
  lib,
  pkgs-stable,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.authentication;

  format = pkgs-stable.formats.yaml {};

  isYaml = file: (lib.strings.hasSuffix ".yml" file) || (lib.strings.hasSuffix ".yaml" file);
  isYamlFile = name: type: type == "regular" && (isYaml name);
  configFiles = builtins.map (file: ./. + "/${file}") (
    lib.attrsets.attrNames (
      lib.attrsets.filterAttrs isYamlFile (builtins.readDir ./.)
    )
  );

  secretInstance = key: {
    inherit key;
    inherit (cfg) sopsFile;

    owner = config.users.users.authelia.name;
    group = config.users.users.authelia.group;

    restartUnits = [config.systemd.services.authelia-default.name];
  };

  rootDomain = lib.strings.concatStringsSep "." (
    lib.lists.reverseList (
      lib.lists.take 2 (
        lib.lists.reverseList (
          lib.strings.splitString "." cfg.domain
        )
      )
    )
  );
  cookieDomains = format.generate "cookies.yml" {
    session.cookies = [
      {
        domain = rootDomain;
        authelia_url = "https://${cfg.domain}";
        default_redirection_url = "https://${rootDomain}";
        same_site = "lax";
      }
    ];
  };
in {
  options.components.authentication = {
    enable = lib.mkEnableOption "Enable the Authelia component";
    sopsFile = extra.mkSecretSourceOption config;

    domain = lib.mkOption {
      type = lib.types.str;
      example = "auth.example.com";
      description = "The domain to use for the Authelia instance";
    };

    secrets = {
      jwt = extra.mkSecretOption "identity validation JWT secret" "authentication/secrets/jwt";
      session = extra.mkSecretOption "session secret" "authentication/secrets/session";
      storage = extra.mkSecretOption "storage secret" "authentication/secrets/storage";
    };

    passwordResetUrl = lib.mkOption {
      type = lib.types.str;
      example = "https://auth.example.com/reset";
      description = "The external URL to use for password resets";
    };

    ldap = {
      address = extra.mkSecretOption "LDAP address" "authentication/ldap/address";
      implementation = lib.mkOption {
        type = lib.types.enum ["custom" "activedirectory" "rfc2307bis" "freeipa" "lldap" "glauth"];
        default = "custom";
        description = "The LDAP implementation to use";
      };

      baseDN = extra.mkSecretOption "LDAP base DN" "authentication/ldap/base_dn";
      user = extra.mkSecretOption "LDAP query user" "authentication/ldap/bind/user";
      password = extra.mkSecretOption "LDAP query password" "authentication/ldap/bind/password";

      attributes = {
        username = lib.mkOption {
          type = lib.types.str;
          default = "uid";
          description = "The attribute to use for the username";
        };
        displayName = lib.mkOption {
          type = lib.types.str;
          default = "displayName";
          description = "The attribute to use for the display name";
        };
        email = lib.mkOption {
          type = lib.types.str;
          default = "mail";
          description = "The attribute to use for the email";
        };
        memberOf = lib.mkOption {
          type = lib.types.str;
          default = "memberOf";
          description = "The attribute to use for the group membership (only used for 'memberOf' group search mode)";
        };
        groupName = lib.mkOption {
          type = lib.types.str;
          default = "cn";
          description = "The attribute to use for the group name";
        };
      };

      filters = {
        users = lib.mkOption {
          type = lib.types.str;
          default = "(&({username_attribute}={input})(objectClass=inetOrgPerson))";
          description = "The filter to use for user searches";
        };
        additionalUsersDn = lib.mkOption {
          type = lib.types.str;
          default = "ou=Users";
          description = "The additional DN to use for user searches";
        };

        groups = lib.mkOption {
          type = lib.types.str;
          default = "(member={dn})";
          description = "The filter to use for group searches";
        };
        additionalGroupsDn = lib.mkOption {
          type = lib.types.str;
          default = "ou=Groups";
          description = "The additional DN to use for group searches";
        };
      };
    };

    smtp = {
      address = extra.mkSecretOption "SMTP address" "authentication/smtp/address";
      username = extra.mkSecretOption "SMTP username" "authentication/smtp/username";
      password = extra.mkSecretOption "SMTP password" "authentication/smtp/password";

      from = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Authelia";
          description = "The name to use for the from field in emails";
        };
        address = lib.mkOption {
          type = lib.types.str;
          default = "no-reply@${cfg.domain}";
          description = "The email to use for the from field in emails";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.components.database.enable;
        message = "The database component must be enabled to use Authelia";
      }
      {
        assertion = config.components.reverseProxy.enable;
        message = "The reverse proxy component must be enabled to use Authelia";
      }
    ];

    components.database.databases = ["authelia"];

    services.authelia.instances.default = {
      enable = true;
      package = pkgs-unstable.authelia;

      user = "authelia";
      group = "authelia";

      settings.server = {
        host = "::1";
        port = 2884;
      };

      settings.log = {
        level = "info";
        format = "text";
      };

      settings.theme = "grey";
      settings.default_2fa_method = "webauthn";

      settingsFiles = configFiles ++ [config.sops.templates."authentication.yml".path cookieDomains];
      environmentVariables = {
        AUTHELIA_ACCESS_CONTROL_DEFAULT_POLICY = "two_factor"; # TODO: change based on number of access rules

        AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = config.sops.secrets."authentication/secrets/jwt".path;

        AUTHELIA_SESSION_REDIS_HOST = config.services.redis.servers.authelia.unixSocket;
        AUTHELIA_SESSION_SECRET_FILE = config.sops.secrets."authentication/secrets/session".path;

        AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = config.sops.secrets."authentication/secrets/storage".path;

        AUTHELIA_TOTP_ISSUER = cfg.domain;

        AUTHELIA_NOTIFIER_SMTP_SENDER = "${cfg.smtp.from.name} <${cfg.smtp.from.address}>";
        AUTHELIA_NOTIFIER_SMTP_IDENTIFIER = cfg.domain;

        AUTHELIA_AUTHENTICATION_BACKEND_PASSWORD_RESET_CUSTOM_URL = cfg.passwordResetUrl;
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.sops.secrets."authentication/ldap/bind/password".path;
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_IMPLEMENTATION = cfg.ldap.implementation;
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_USERS_FILTER = cfg.ldap.filters.users;
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_ADDITIONAL_USERS_DN = cfg.ldap.filters.additionalUsersDn;
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_GROUPS_FILTER = cfg.ldap.filters.groups;
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_ADDITIONAL_GROUPS_DN = cfg.ldap.filters.additionalGroupsDn;
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_ATTRIBUTES_USERNAME = cfg.ldap.attributes.username;
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_ATTRIBUTES_DISPLAY_NAME = cfg.ldap.attributes.displayName;
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_ATTRIBUTES_MAIL = cfg.ldap.attributes.email;
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_ATTRIBUTES_MEMBER_OF = cfg.ldap.attributes.memberOf;
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_ATTRIBUTES_GROUP_NAME = cfg.ldap.attributes.groupName;

        AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.sops.secrets."authentication/smtp/password".path;
      };

      secrets.manual = true;
    };

    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;

      locations = let
        server = config.services.authelia.instances.default.settings.server;
        upstream = "http://[${server.host}]:${builtins.toString server.port}";
      in {
        "/api/verify" = {
          proxyPass = upstream;
          recommendedProxySettings = false;
        };

        "/".proxyPass = upstream;
      };
    };

    services.redis.package = pkgs-unstable.redis;
    services.redis.servers.authelia = {
      enable = true;
      databases = 1;
    };

    users.users.authelia = {
      isSystemUser = true;
      group = config.users.groups.authelia.name;
      extraGroups = [config.services.redis.servers.authelia.user];
    };
    users.groups.authelia = {};

    sops.secrets = {
      "authentication/secrets/jwt" = secretInstance cfg.secrets.jwt;
      "authentication/secrets/session" = secretInstance cfg.secrets.session;
      "authentication/secrets/storage" = secretInstance cfg.secrets.storage;
      "authentication/ldap/address" = secretInstance cfg.ldap.address;
      "authentication/ldap/base_dn" = secretInstance cfg.ldap.baseDN;
      "authentication/ldap/bind/user" = secretInstance cfg.ldap.user;
      "authentication/ldap/bind/password" = secretInstance cfg.ldap.password;
      "authentication/smtp/address" = secretInstance cfg.smtp.address;
      "authentication/smtp/username" = secretInstance cfg.smtp.username;
      "authentication/smtp/password" = secretInstance cfg.smtp.password;
    };

    sops.templates."authentication.yml" = {
      content = builtins.toJSON {
        authentication_backend.ldap = {
          address = config.sops.placeholder."authentication/ldap/address";
          base_dn = config.sops.placeholder."authentication/ldap/base_dn";
          user = config.sops.placeholder."authentication/ldap/bind/user";
        };
        notifier.smtp = {
          address = config.sops.placeholder."authentication/smtp/address";
          username = config.sops.placeholder."authentication/smtp/username";
        };
      };

      owner = config.users.users.authelia.name;
      group = config.users.users.authelia.group;
    };
  };
}
