# Host descriptor: m5, the personal Apple Silicon Mac.
#
# Role-level config (apps, git identity, Claude Code) comes from the
# profiles listed below (nix/profiles/); this directory holds only what is
# specific to this machine.
{
  hostname = "m5";
  username = "yvan-sytac";

  profiles = [
    "dev"
    "personal"
  ];

  # nix-darwin modules unique to this host (live in this directory).
  systemModules = [ ./dock.nix ];

  # nix-darwin module applied only to this host.
  module = { ... }: {
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.stateVersion = 5;
    system.primaryUser = "yvan-sytac";

    # Declare the user so home-manager can read users.users.yvan-sytac.home.
    users.users.yvan-sytac.home = "/Users/yvan-sytac";
  };
}
