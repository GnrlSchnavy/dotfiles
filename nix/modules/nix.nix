{ ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "@admin" "yvan" ];
    auto-optimise-store = true;
    warn-dirty = false;
  };

  # Garbage-collect nix store generations older than 30 days.
  # Runs Sundays at 3am via launchd.
  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 3; };
    options = "--delete-older-than 30d";
  };

  # Hardlink-deduplicate identical files in /nix/store.
  # Typically reclaims 20-40% of store size.
  nix.optimise.automatic = true;
}
