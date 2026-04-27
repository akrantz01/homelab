{
  config,
  host,
  pkgs-unstable,
  ...
}: let
  firstBoot = host.firstBoot or false;
in {
  services.tailscale = {
    enable = !firstBoot;
    package = pkgs-unstable.tailscale;

    openFirewall = true;

    authKeyFile = config.sops.secrets."tailscale/key".path;
    extraUpFlags = ["--ssh"];
  };

  networking.firewall.trustedInterfaces = ["tailscale0"];

  sops.secrets."tailscale/key" = {};
}
