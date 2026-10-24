{ config, lib, ... }:

let
  user = config.system.primaryUser;
  inherit (config.users.users.${user}) home;
in
{
  # The Proton Pass SSH agents (nix/home/ssh.nix) restart every minute while
  # pass-cli is logged out, each time adding to their log. macOS's newsyslog
  # rotates those logs at 1 MB and keeps three.
  environment.etc."newsyslog.d/dotfiles.conf".text = ''
    # logfilename  [owner:group]  mode  count  size(KB)  when  flags
    ${home}/Library/Logs/proton-pass-*.log  ${user}:staff  600  3  1024  *  GN
  '';

  # nix-darwin can't turn on disk encryption, so every rebuild says so while
  # FileVault is off.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    if ! fdesetup isactive >/dev/null 2>&1; then
      echo "warning: FileVault is off; turn it on in System Settings → Privacy & Security" >&2
    fi
  '';

  # Touch ID for sudo (every rebuild needs it). reattach lets it work inside
  # tmux too. Without a sensor, sudo just asks for the password.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # System keyboard configuration
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  # macOS system defaults
  system.defaults = {
    # Screen saver settings
    screensaver = {
      # Password as soon as the screen locks.
      # Recent macOS may ignore these keys; if Lock Screen settings still
      # show a delay, run once: sysadminctl -screenLock immediate -password -
      askForPassword = true;
      askForPasswordDelay = 0;
    };

    # Login window configuration
    # Lost-device text: per host (nix/hosts/m5), not on the client Mac.
    loginwindow.GuestEnabled = false;

    # Window manager settings
    WindowManager.EnableStandardClickToShowDesktop = false;

    # Finder configuration
    finder = {
      NewWindowTarget = "Home";
      ShowExternalHardDrivesOnDesktop = false;
      ShowPathbar = true;
      FXPreferredViewStyle = "clmv";
    };

    # Global system preferences
    NSGlobalDomain = {
      # Animation and UI settings
      NSScrollAnimationEnabled = false;
      NSAutomaticWindowAnimationsEnabled = false;

      # Text input settings
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      ApplePressAndHoldEnabled = false;

      # File and document settings
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      AppleShowAllExtensions = true;

      # Interface settings
      AppleInterfaceStyle = "Dark";
      "com.apple.swipescrolldirection" = false;

      # Keyboard settings
      KeyRepeat = 2;
      InitialKeyRepeat = 15;

      # Mouse and sound settings
      "com.apple.mouse.tapBehavior" = 1;
      "com.apple.sound.beep.volume" = 0.0;
      "com.apple.sound.beep.feedback" = 0;
    };
  };
}
