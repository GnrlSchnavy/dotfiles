{ ... }:

let
  # Build a /Applications path from an app name (without `.app`).
  app = name: "/Applications/${name}.app";
in
{
  system.defaults.dock = {
    # Dock behavior
    show-recents = false;
    static-only = true;
    minimize-to-application = true;
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
    persistent-apps = map app [
      "Brave Browser"
      "Spotify"
      "Slack"
      "Obsidian"
      "IntelliJ IDEA"
    ];
  };
}
