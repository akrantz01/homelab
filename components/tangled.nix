{
  config,
  extra,
  lib,
  ...
}: let
  cfg = config.components.tangled;
  knot = config.services.tangled.knot;

  listenAddr = "127.0.0.1:5555";
  gitUser = "git";
in {
  options.components.tangled = {
    enable = lib.mkEnableOption "Enable the Tangled component";
    sopsFile = extra.mkSecretSourceOption config;

    domain = lib.mkOption {
      type = lib.types.str;
      example = "knot.example.com";
      description = "Domain for the server";
    };

    owner = lib.mkOption {
      type = lib.types.str;
      description = "The owner's DID";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      tangled.knot = {
        enable = true;

        inherit gitUser;

        stateDir = "/var/lib/tangled-knot";
        repo.scanPath = "${knot.stateDir}/repos";

        server = {
          inherit listenAddr;
          hostname = cfg.domain;
          owner = cfg.owner;
        };
      };

      openssh = {
        enable = lib.mkForce true;
        settings = {
          AllowUsers = [gitUser];
          AllowGroups = [gitUser];
        };
      };
    };

    components.reverseProxy.hosts.${cfg.domain}.locations."/".proxyTo = "http://${listenAddr}";
  };
}
