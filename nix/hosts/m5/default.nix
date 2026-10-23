# Host descriptor: m5, the personal Apple Silicon Mac.
#
# Role-level config (apps, git identity, Claude Code) comes from the
# profiles listed below (nix/profiles/); this directory holds only what is
# specific to this machine.
{
  hostname = "m5";
  username = "yvan";

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
    system.primaryUser = "yvan";

    # Declare the user so home-manager can read users.users.yvan.home.
    users.users.yvan.home = "/Users/yvan";

    # Lost-device contact. This repo is public, so no phone number here;
    # the address is already public as the git identity.
    system.defaults.loginwindow.LoginwindowText = "Yvan Stemmerik · yvanstemmerik@gmail.com";
  };
}
