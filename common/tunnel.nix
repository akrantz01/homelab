{
  config,
  pkgs-unstable,
  ...
}: {
  services.tailscale = {
    enable = true;
    package = pkgs-unstable.tailscale;

    openFirewall = true;

    authKeyFile = config.sops.secrets."tailscale/key".path;
    extraUpFlags = ["--ssh"];
  };

  sops.secrets."tailscale/key" = {};
}
