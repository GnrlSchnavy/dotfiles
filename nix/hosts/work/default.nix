# Host descriptor: the client-issued work Mac.
#
# TODO when the machine arrives: replace `changeme` (three places) with
# `whoami`. setup.sh and darwin-rebuild pick the config by
# `scutil --get LocalHostName`, so either set that to `work`
# (sudo scutil --set LocalHostName work) or rename this directory, the
# hostname below and the `work` entry in nix/flake.nix to match it.
{
  hostname = "work";
  username = "changeme";

  profiles = [
    "dev"
    "work"
  ];

  # nix-darwin modules unique to this host (live in this directory).
  systemModules = [ ./dock.nix ];

  # nix-darwin module applied only to this host.
  module = { ... }: {
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.stateVersion = 5;
    system.primaryUser = "changeme";

    # Declare the user so home-manager can read users.users.<name>.home.
    users.users.changeme.home = "/Users/changeme";
  };
}
