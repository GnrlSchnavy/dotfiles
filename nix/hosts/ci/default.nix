# CI host descriptor.
#
# Matches the GitHub Actions xcode-27 (macOS 27) runner so the CI
# pipeline can apply the full config (`darwin-rebuild switch`) end-to-end
# as a fresh-install test. Not intended for use on a real machine.
{
  hostname = "ci";
  username = "runner";

  # Use the runner's pre-installed Homebrew instead of letting
  # nix-homebrew install/migrate its own. Since the July 2026 runner
  # images, /opt/homebrew is no longer a git checkout, so autoMigrate
  # fails with "does not look like a Homebrew checkout". brew bundle
  # (homebrew.*) still runs against the existing install.
  manageHomebrew = false;

  # CI mirrors m5 (its profiles and its dock) so we exercise the real config
  # end-to-end. Casks are force-dropped in runner.nix; brews still run.
  # ci-work does the same for the work Mac.
  profiles = [
    "dev"
    "personal"
  ];
  systemModules = [ ../m5/dock.nix ];

  module = import ./runner.nix;
}
