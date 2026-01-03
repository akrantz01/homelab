{
  config,
  extra,
  lib,
  pkgs-unstable,
  ...
}: let
  cfg = config.components.karakeep;

  port = 5272;

  aiEnabled = cfg.ai.autoSummarization || cfg.ai.autoTagging;
in {
  options.components.karakeep = {
    enable = lib.mkEnableOption "Enable the Karakeep component";
    sopsFile = extra.mkSecretSourceOption config;

    domain = lib.mkOption {
      type = lib.types.str;
      example = "links.example.com";
      description = "The domain to use for the Karakeep instance";
    };

    ai = {
      autoSummarization = lib.mkEnableOption "Enable automatic summarization via AI";
      autoTagging = lib.mkEnableOption "Enable automatic tagging via AI";

      apiKey = extra.mkSecretOption "OpenAI API Key" "karakeep/openai_key";

      language = lib.mkOption {
        type = lib.types.str;
        default = "english";
        description = "The language to generate in";
      };

      models = {
        text = lib.mkOption {
          type = lib.types.str;
          default = "gpt-4.1-mini";
          description = "The model to use for text inference";
        };
        image = lib.mkOption {
          type = lib.types.str;
          default = "gpt-4o-mini";
          description = "The model to use for image inference";
        };
        embedding = lib.mkOption {
          type = lib.types.str;
          default = "text-embedding-3-small";
          description = "The model to use for generating embeddings";
        };
      };
    };

    oauth = {
      enable = lib.mkEnableOption "Enable authentication using OAuth";

      name = lib.mkOption {
        type = lib.types.str;
        default = "Custom Provider";
        description = "The name of the provider. Shown on the signup page as 'Sign in with [name]'";
      };

      discoveryEndpoint = lib.mkOption {
        type = lib.types.str;
        example = "https://accounts.google.com/.well-known/openid-configuration";
        description = "The OIDC discovery endpoint to use for the provider";
      };

      clientId = extra.mkSecretOption "OAuth client ID" "karakeep/oauth/client_id";
      clientSecret = extra.mkSecretOption "OAuth client secret" "karakeep/oauth/client_secret";

      scopes = lib.mkOption {
        type = with lib.types; listOf str;
        default = ["openid" "email" "profile"];
        description = "The full list of scopes to request from the provider";
      };
    };

    smtp = {
      enable = lib.mkEnableOption "Enable SMTP for sending emails";

      host = extra.mkSecretOption "SMTP host" "karakeep/smtp/host";
      port = extra.mkSecretOption "SMTP port" "karakeep/smtp/port";
      username = extra.mkSecretOption "SMTP username" "karakeep/smtp/username";
      password = extra.mkSecretOption "SMTP password" "karakeep/smtp/password";

      secure = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to use SSL/TLS encryption. Set to true for port 465 and false for 587 with STARTTLS";
      };

      from = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Karakeep";
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
        assertion = config.components.reverseProxy.enable;
        message = "The reverse proxy component must be enabled to use Karakeep";
      }
      {
        assertion = config.components.meilisearch.enable;
        message = "The Meilisearch component must be enabled to use Karakeep";
      }
    ];

    services.karakeep = {
      enable = true;
      package = pkgs-unstable.karakeep;

      meilisearch.enable = true;
      browser.enable = false;

      environmentFile = config.sops.templates."karakeep.env".path;
      extraEnvironment = lib.mergeAttrsList [
        {
          PORT = toString port;
          LOG_LEVEL = "notice";

          DISABLE_SIGNUPS = lib.boolToString (!cfg.oauth.enable);
          DISABLE_NEW_RELEASE_CHECK = "true";

          NEXTAUTH_URL = "https://${cfg.domain}";
        }
        (lib.optionalAttrs aiEnabled {
          INFERENCE_ENABLE_AUTO_SUMMARIZATION = lib.boolToString cfg.ai.autoSummarization;
          INFERENCE_ENABLE_AUTO_TAGGING = lib.boolToString cfg.ai.autoTagging;

          INFERENCE_LANG = cfg.ai.language;

          INFERENCE_TEXT_MODEL = cfg.ai.models.text;
          INFERENCE_IMAGE_MODEL = cfg.ai.models.image;
          EMBEDDING_TEXT_MODEL = cfg.ai.models.embedding;
        })
        (lib.optionalAttrs cfg.oauth.enable {
          DISABLE_PASSWORD_AUTH = "true";
          OAUTH_WELLKNOWN_URL = cfg.oauth.discoveryEndpoint;
          OAUTH_SCOPE = lib.concatStringsSep " " cfg.oauth.scopes;
          OAUTH_PROVIDER_NAME = cfg.oauth.name;
        })
        (lib.optionalAttrs cfg.smtp.enable {
          SMTP_SECURE = lib.boolToString cfg.smtp.secure;
          SMTP_FROM = "\"${cfg.smtp.from.name}\" <${cfg.smtp.from.address}>";
        })
      ];
    };

    components.reverseProxy.hosts.${cfg.domain}.locations."/".proxyTo = "http://127.0.0.1:${toString port}";

    sops.secrets = let
      instance = key: {
        inherit (cfg) sopsFile;
        inherit key;

        owner = config.users.users.karakeep.name;
        group = config.users.users.karakeep.group;

        restartUnits = with config.systemd.services; [karakeep-web.name karakeep-workers.name];
      };
    in
      lib.mergeAttrsList [
        (lib.optionalAttrs aiEnabled {
          "karakeep/openai_key" = instance cfg.ai.apiKey;
        })
        (lib.optionalAttrs cfg.oauth.enable {
          "karakeep/oauth/client_id" = instance cfg.oauth.clientId;
          "karakeep/oauth/client_secret" = instance cfg.oauth.clientSecret;
        })
        (lib.optionalAttrs cfg.smtp.enable {
          "karakeep/smtp/host" = instance cfg.smtp.host;
          "karakeep/smtp/port" = instance cfg.smtp.port;
          "karakeep/smtp/username" = instance cfg.smtp.username;
          "karakeep/smtp/password" = instance cfg.smtp.password;
        })
      ];

    sops.templates."karakeep.env" = {
      content = lib.concatStringsSep "\n" [
        (lib.optionalString aiEnabled ''
          OPENAI_API_KEY=${config.sops.placeholder."karakeep/openai_key"}
        '')
        (lib.optionalString cfg.oauth.enable ''
          OAUTH_CLIENT_ID=${config.sops.placeholder."karakeep/oauth/client_id"}
          OAUTH_CLIENT_SECRET=${config.sops.placeholder."karakeep/oauth/client_secret"}
        '')
        (lib.optionalString cfg.smtp.enable ''
          SMTP_HOST=${config.sops.placeholder."karakeep/smtp/host"}
          SMTP_PORT=${config.sops.placeholder."karakeep/smtp/port"}
          SMTP_USERNAME=${config.sops.placeholder."karakeep/smtp/username"}
          SMTP_PASSWORD=${config.sops.placeholder."karakeep/smtp/password"}
        '')
      ];

      owner = config.users.users.karakeep.name;
      group = config.users.users.karakeep.group;

      restartUnits = with config.systemd.services; [karakeep-web.name karakeep-workers.name];
    };
  };
}
