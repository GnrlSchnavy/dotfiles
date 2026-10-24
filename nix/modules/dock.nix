# Dock behaviour, the same on every Mac. Each host's dock.nix lists only
# its apps (system.defaults.dock.persistent-apps).
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
  };
}
