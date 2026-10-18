# Homebrew, on every host. The casks and brews themselves come from the
# host's profiles (nix/profiles/*/homebrew.nix) and the host's own modules.
{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      # Anything not declared for the host is uninstalled on rebuild:
      # removing a line is how software gets uninstalled, and manual
      # `brew install`s don't survive.
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };
}
