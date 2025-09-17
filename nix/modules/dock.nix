{ pkgs, ... }:

{
  system.defaults.dock = {
    # Dock behavior
    show-recents = false;
    static-only = true;
    minimize-to-application = true;
    mineffect = null;
    launchanim = false;
    autohide = true;
    
    # Dock appearance
    orientation = "right";
    tilesize = 36;
    magnification = false;
    
    # Dock timing
    autohide-delay = 0.01;
    autohide-time-modifier = 0.1;
    
    # Persistent applications
    persistent-apps = [
      "${pkgs.brave}/Applications/Brave Browser.app"
      "/Applications/Spotify.app"  # Installed via Homebrew
      "${pkgs.slack}/Applications/Slack.app"
      "${pkgs.obsidian}/Applications/Obsidian.app"
      "/Applications/IntelliJ IDEA.app"
    ];
  };
}