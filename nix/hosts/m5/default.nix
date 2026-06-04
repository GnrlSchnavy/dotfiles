# Host-specific configuration for the "m5" Apple Silicon Mac.
#
# Per-host modules (homebrew, packages, dock, git) live in THIS directory.
# They were seeded as copies of m4 — prune/edit them freely; changes here
# do NOT affect m4. Everything in nix/modules/ and nix/home/ is shared.
{
  hostname = "m5";
  username = "yvan-sytac";

  # nix-darwin modules unique to this host (live in this directory).
  systemModules = [ ./homebrew.nix ./packages.nix ./dock.nix ];

  # home-manager modules unique to this host (live in this directory).
  homeModules = [ ./git.nix ];

  # nix-darwin module applied only to this host.
  module = { ... }: {
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.stateVersion = 5;
    system.primaryUser = "yvan-sytac";

    # Declare the user so home-manager can read users.users.yvan-sytac.home.
    users.users.yvan-sytac.home = "/Users/yvan-sytac";
  };
}
