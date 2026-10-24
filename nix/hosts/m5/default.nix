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

    # Security updates stay automatic (check, download, install security
    # responses and system data files) and Remote Login (sshd) stays off,
    # re-applied on every rebuild. The absolute domain writes the system
    # file; a bare one would go to root's own preferences.
    system.defaults.CustomSystemPreferences."/Library/Preferences/com.apple.SoftwareUpdate" = {
      AutomaticCheckEnabled = true;
      AutomaticDownload = true;
      CriticalUpdateInstall = true;
      ConfigDataInstall = true;
    };
    services.openssh.enable = false;
  };
}
