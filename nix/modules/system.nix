{ ... }:

{
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
      # Password as soon as the screen locks: this Mac holds client code.
      # Recent macOS may ignore these keys; if Lock Screen settings still
      # show a delay, run once: sysadminctl -screenLock immediate -password -
      askForPassword = true;
      askForPasswordDelay = 0;
    };

    # Login window configuration
    loginwindow = {
      LoginwindowText = "Yvan Stemmerik +31610042024";
      GuestEnabled = false;
    };

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
