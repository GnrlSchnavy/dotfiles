# CI host for the work Mac's profiles: the `ci` runner setup (../ci/runner.nix)
# with `work` instead of `personal`, so CI installs the work config too.
# Installing needs neither DevAI nor a Proton Pass login; only launching
# cc-work does. Not intended for use on a real machine.
{
  hostname = "ci-work";
  username = "runner";

  profiles = [
    "dev"
    "work"
  ];
  systemModules = [ ../work/dock.nix ];

  module = import ../ci/runner.nix;
}
