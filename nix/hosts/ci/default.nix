# CI host descriptor.
#
# Matches the GitHub Actions macos-15 runner environment so the CI
# pipeline can apply the full config (`darwin-rebuild switch`) end-to-end
# as a fresh-install test. Not intended for use on a real machine.
{
  hostname = "ci";
  username = "runner";

  module =
    { lib, ... }:
    {
      nixpkgs.config.allowUnfree = true;

      # GitHub-hosted macos-15 runners are Apple Silicon.
      nixpkgs.hostPlatform = "aarch64-darwin";

      system.stateVersion = 5;
      system.primaryUser = "runner";

      # Required so home-manager can read users.users.<name>.home.
      users.users.runner.home = "/Users/runner";

      # --- Homebrew CI overrides ---
      # We still run brew bundle so we exercise the activation path,
      # but tune the actual workload to what's safe and useful in CI.

      # Don't zap the runner's pre-installed Homebrew packages — they
      # aren't part of our config and removing them mid-CI would slow
      # the run and could break other workflow steps that rely on them.
      homebrew.onActivation.cleanup = lib.mkForce "none";

      # Skip auto-upgrade — fresh runners have nothing to upgrade and
      # this avoids unrelated upstream regressions failing our CI.
      homebrew.onActivation.upgrade = lib.mkForce false;

      # Drop GUI casks for CI. They're slow (multi-GB), don't add
      # much coverage (we test brew bundle *runs*, not that every
      # specific cask installs), and a few have DSL incompatibilities
      # with the macos-15 runner's Homebrew that don't reproduce on
      # real machines. Brews still run — they're smaller, exercise
      # the same brew-bundle path, and surface real config issues.
      homebrew.casks = lib.mkForce [ ];
    };
}
