{ ... }:

{
  # System keyboard configuration
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  # macOS system defaults
  system.defaults = {
    # Screen saver settings
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 300;
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