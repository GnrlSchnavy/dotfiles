{ ... }:

{
  # Allow unfree packages (Slack, IntelliJ, VSCode, etc.) when they
  # appear in nixpkgs. Set here once instead of repeating per host.
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # @admin covers any user in the admin group, which is the default
    # for the primaryUser on macOS — no need to hardcode a username.
    trusted-users = [ "@admin" ];
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
