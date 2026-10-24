# CI host descriptor.
#
# Matches the GitHub Actions xcode-27 (macOS 27) runner so the CI
# pipeline can apply the full config (`darwin-rebuild switch`) end-to-end
# as a fresh-install test. Not intended for use on a real machine.
{
  hostname = "ci";
  username = "runner";

  # Homebrew is nix-homebrew's, as on the Macs: CI moves the runner's own
  # /opt/homebrew aside first (it isn't a git checkout, so autoMigrate
  # can't adopt it), then setup.sh installs Homebrew as on a new Mac.

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
