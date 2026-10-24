# Trust the third-party Homebrew formulae and casks this host installs, one
# by one. Newer Homebrew refuses to load anything from a third-party tap
# that isn't trusted ("Refusing to load formula ... from untrusted tap"),
# aborting brew bundle; trusting the whole tap instead would also cover
# anything it publishes later. The list comes from the host's own
# homebrew.brews/casks ("owner/tap/name" entries), so declaring one is all
# it takes. nix-homebrew writes the entries before brew bundle runs, so it's
# imported with nix-homebrew (nix/flake.nix). Trust stays when an entry
# goes: `brew untrust --formula <owner/tap/name>` (docs/operations.md).
{ config, lib, ... }:
let
  # brews/casks entries may be plain strings or attrsets ({ name = ...; }).
  nameOf = entry: if lib.isString entry then entry else entry.name or "";
  thirdParty =
    entries: lib.filter (name: lib.length (lib.splitString "/" name) == 3) (map nameOf entries);
in
{
  nix-homebrew.trust = {
    formulae = thirdParty config.homebrew.brews;
    casks = thirdParty config.homebrew.casks;
  };
}
