# Autostart brew-services-menubar at login.
#
# The app has no autostart option of its own — upstream's README says to
# add it to System Preferences → Login Items by hand. This launchd user
# agent is the declarative equivalent: RunAtLoad fires once per login
# session and `open -g` launches the app without stealing focus.
#
# The app is unsigned upstream, so Gatekeeper would block its first
# launch. The Brewfile `no_quarantine` cask arg can't be used for this:
# Homebrew 6's bundle passes args verbatim as `--no_quarantine`, an
# invalid flag (the underscore→hyphen translation was dropped), and
# nix-darwin's typed cask args can't emit the hyphenated key. Instead,
# postActivation (which runs right after the homebrew bundle step)
# strips the quarantine attribute and kickstarts the agent so the app
# is running from the very first rebuild, not just the next login.
#
# Guarded on the cask actually being declared by the host, so hosts
# without it (e.g. ci, which force-drops all casks) get neither piece.
{ config, lib, ... }:
let
  caskNames = map (c: if lib.isString c then c else c.name or "") config.homebrew.casks;
  hasCask = lib.elem "brewservicesmenubar" caskNames;
  user = config.system.primaryUser;
  app = "/Applications/BrewServicesMenubar.app";
in
{
  launchd.user.agents.brew-services-menubar = lib.mkIf hasCask {
    serviceConfig = {
      ProgramArguments = [
        "/usr/bin/open"
        "-g"
        "-a"
        "BrewServicesMenubar"
      ];
      RunAtLoad = true;
    };
  };

  system.activationScripts.postActivation.text = lib.mkIf hasCask ''
    if [ -d ${app} ]; then
      # Unquarantine the unsigned app (see header comment) and start it
      # now if it isn't already running; kickstart without -k never
      # restarts a running instance.
      xattr -dr com.apple.quarantine ${app} 2>/dev/null || true
      launchctl kickstart "gui/$(id -u ${user})/org.nixos.brew-services-menubar" 2>/dev/null || true
    fi
  '';
}
