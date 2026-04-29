# Template host descriptor.
#
# Copy this directory to nix/hosts/<your-hostname>/ and edit the values
# below. Then register it in nix/flake.nix:
#
#   hosts = {
#     m4 = import ./hosts/m4;
#     <your-hostname> = import ./hosts/<your-hostname>;
#   };
#
# `git add nix/hosts/<your-hostname>/` so Nix can see the new files
# (flakes only read git-tracked content).
{
  # Must match `scutil --get LocalHostName` on the target machine.
  hostname = "REPLACE_ME_HOSTNAME";

  # Must match the macOS account name (whoami).
  username = "REPLACE_ME_USERNAME";

  # nix-darwin module applied only to this host.
  module = { ... }: {
    # "aarch64-darwin" for Apple Silicon, "x86_64-darwin" for Intel.
    nixpkgs.hostPlatform = "aarch64-darwin";

    # Bump only after reading the nix-darwin release notes for the
    # new value. Leaving at 5 is safe for fresh setups in 2026.
    system.stateVersion = 5;

    # Account that owns user-level system options (homebrew, dock, etc.).
    system.primaryUser = "REPLACE_ME_USERNAME";

    # Required so home-manager can read users.users.<name>.home.
    # Without this the rebuild fails with a null-not-an-absolute-path
    # error from home-manager's common.nix.
    users.users.REPLACE_ME_USERNAME.home = "/Users/REPLACE_ME_USERNAME";
  };
}
