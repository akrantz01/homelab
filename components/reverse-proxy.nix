{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.components.reverseProxy;
in {
  options.components.reverseProxy = {
    enable = lib.mkEnableOption "Enable the reverse proxy component";
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      enableReload = true;

      package = pkgs.nginxQuic;
      additionalModules = with pkgs.nginxModules; [moreheaders];

      recommendedTlsSettings = true;
      recommendedProxySettings = true;
      recommendedOptimisation = true;
      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedZstdSettings = true;
    };
  };
}
