# Autostart brew-services-menubar at login.
#
# The app has no autostart option of its own — upstream's README says to
# add it to System Preferences → Login Items by hand. This launchd user
# agent is the declarative equivalent: RunAtLoad fires once per login
# session and `open -g` launches the app without stealing focus.
#
# Guarded on the cask actually being declared by the host, so hosts
# without it (e.g. ci, which force-drops all casks) get no agent.
{ config, lib, ... }:
let
  caskNames = map (c: if lib.isString c then c else c.name or "") config.homebrew.casks;
  hasCask = lib.elem "brewservicesmenubar" caskNames;
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
}
