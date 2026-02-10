{ ... }:

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
    
    # Persistent applications (all installed via Homebrew casks)
    persistent-apps = [
      "/Applications/Brave Browser.app"
      "/Applications/Spotify.app"
      "/Applications/Slack.app"
      "/Applications/Obsidian.app"
      "/Applications/IntelliJ IDEA.app"
    ];
  };
}