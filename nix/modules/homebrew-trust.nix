# Trust third-party Homebrew taps declaratively.
#
# Newer Homebrew (mid-2026) refuses to load formulae from untrusted
# third-party taps, aborting brew bundle during activation with
# "Refusing to load formula ... from untrusted tap". The tap list is
# derived from this host's own homebrew declarations ("owner/tap/name"
# brews and casks, plus homebrew.taps), so declaring a tap-sourced
# package is all that's ever needed — rebuilds, fresh installs, and CI
# all trust it through this module.
#
# Runs in preActivation (before the homebrew bundle step), as the
# primary user (brew refuses to run as root), mirroring nix-darwin's
# own brew-bundle invocation: --set-home is required — without it brew
# runs with root's HOME and cannot write the trust settings.
# Idempotent; no-op when brew is absent or predates trust gating
# (`brew trust` unknown).
{ config, lib, ... }:
let
  # "owner/tap/name" → "owner/tap"; plain names contribute nothing.
  tapOf =
    name:
    let
      parts = lib.splitString "/" name;
    in
    lib.optional (lib.length parts == 3) (lib.concatStringsSep "/" (lib.take 2 parts));

  # brews/casks/taps entries may be plain strings or attrsets ({ name = ...; }).
  nameOf = entry: if lib.isString entry then entry else entry.name or "";

  declared = map nameOf (config.homebrew.brews ++ config.homebrew.casks);
  taps = lib.unique ((map nameOf config.homebrew.taps) ++ lib.concatMap tapOf declared);

  brew = "${config.homebrew.brewPrefix}/brew";
  user = config.system.primaryUser;
  runBrew = "PATH=\"${config.homebrew.brewPrefix}:$PATH\" sudo --preserve-env=PATH --set-home --user=${user} ${brew}";
in
{
  system.activationScripts.preActivation.text =
    lib.mkIf (config.homebrew.enable && taps != [ ]) ''
      if [ -x ${brew} ] && ${runBrew} trust --help >/dev/null 2>&1; then
        echo "trusting third-party Homebrew taps..." >&2
        ${lib.concatMapStringsSep "\n  " (tap: ''
          ${runBrew} trust ${tap} >/dev/null 2>&1 \
              || echo "warning: could not trust Homebrew tap ${tap}" >&2'') taps}
      fi
    '';
}
