# The GitHub Actions runner side of a CI host, shared by `ci` (m5's
# profiles) and `ci-work` (the work Mac's): the runner user, and Homebrew
# tuned for a throwaway machine.
{ lib, ... }:
{
  # GitHub-hosted xcode-27 runners are Apple Silicon.
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.stateVersion = 5;
  system.primaryUser = "runner";

  # Required so home-manager can read users.users.<name>.home.
  users.users.runner.home = "/Users/runner";

  # --- Homebrew CI overrides ---
  # We still run brew bundle so we exercise the activation path,
  # but tune the actual workload to what's safe and useful in CI.

  # cleanup stays "zap", as on the Macs: the runner's own Homebrew is
  # moved aside before the install, so the prefix holds only what this
  # config installed.

  # Skip auto-upgrade — fresh runners have nothing to upgrade and
  # this avoids unrelated upstream regressions failing our CI.
  homebrew.onActivation.upgrade = lib.mkForce false;

  # Drop GUI casks for CI. They're slow (multi-GB), don't add
  # much coverage (we test brew bundle *runs*, not that every
  # specific cask installs), and a few have DSL incompatibilities
  # with the runner's Homebrew that don't reproduce on
  # real machines. Brews still run — they're smaller, exercise
  # the same brew-bundle path, and surface real config issues.
  homebrew.casks = lib.mkForce [ ];
}
