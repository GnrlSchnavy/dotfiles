# Host descriptor: the client-issued work Mac.
#
# Its LocalHostName (an asset tag) is set by the client's device management,
# so the flake host keeps the name `work` instead of matching it. Select it
# explicitly on the first install — DOTFILES_HOST=work ./setup.sh — after
# which the flake sets DOTFILES_HOST=work and rebuilds find it on their own.
{
  hostname = "work";
  username = "pnl1ln25";

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
    system.primaryUser = "pnl1ln25";

    # Declare the user so home-manager can read users.users.<name>.home.
    users.users.pnl1ln25.home = "/Users/pnl1ln25";
  };
}
