# Template host descriptor.
#
# Onboard a new Mac:
#   1. cp -r nix/hosts/template nix/hosts/<your-hostname>
#   2. Seed the per-host modules from an existing host, then prune:
#        cp nix/hosts/m4/{homebrew,packages,dock,git}.nix nix/hosts/<your-hostname>/
#   3. Edit the values below (hostname, username, arch if Intel).
#   4. Register it in nix/flake.nix under the hosts attrset:
#        hosts = {
#          m4 = import ./hosts/m4;
#          <your-hostname> = import ./hosts/<your-hostname>;
#        };
#   5. git add nix/hosts/<your-hostname>/  (flakes only read git-tracked files)
{
  # Must match `scutil --get LocalHostName` on the target machine.
  hostname = "REPLACE_ME_HOSTNAME";

  # Must match the macOS account name (whoami).
  username = "REPLACE_ME_USERNAME";

  # nix-darwin modules unique to this host (live in this directory).
  systemModules = [ ./homebrew.nix ./packages.nix ./dock.nix ];

  # home-manager modules unique to this host (live in this directory).
  homeModules = [ ./git.nix ];

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
