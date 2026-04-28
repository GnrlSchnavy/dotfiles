# Host-specific configuration for the "m4" Apple Silicon Mac.
#
# Anything tied to *this specific machine* (hostname, primary user,
# CPU arch, state version) lives here. Everything in nix/modules/
# is shared across hosts.
{
  hostname = "m4";
  username = "yvan";

  # nix-darwin module applied only to this host.
  module = { ... }: {
    nixpkgs.config.allowUnfree = true;
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.stateVersion = 5;
    system.primaryUser = "yvan";

    # Declare the user so home-manager can read users.users.yvan.home.
    # Without this, home-manager's common.nix sets home.homeDirectory
    # to null and rebuild fails with a type-check error.
    users.users.yvan.home = "/Users/yvan";
  };
}
