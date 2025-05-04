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

  networking.firewall.trustedInterfaces = ["tailscale0"];

  sops.secrets."tailscale/key" = {};
}
