{ ... }:

{
  nix.settings = {
    trusted-users = [ "@wheel" ];
    auto-optimise-store = true;

    extra-experimental-features = [ "nix-command" "flakes" ];
  };

  # Prune the nix store weekly, removing things older than 30 days
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
