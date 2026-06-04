{ ... }:

{
  homebrew = {
    enable = true;

    # GUI Applications (casks) - grouped alphabetically within categories
    casks = [
      # Browsers
      "brave-browser"
      "firefox"
      "google-chrome"

      # Communication
      "microsoft-teams"
      "signal"
      "slack"
      "whatsapp"

      # Productivity
      "alfred"
      "obsidian"
      "rectangle"

      # Development
      "chromedriver"
      "claude"
      "docker-desktop"
      "intellij-idea"
      "visual-studio-code"

      # Media
      "spotify"

      # Networking & Security
      "proton-drive"
      "proton-mail"
      "proton-mail-bridge"
      "proton-pass"
      "protonvpn"
      "warp"

      # Programming languages
      "temurin@25"
    ];

    # CLI Tools (brews) - use when not available in Nix or need Homebrew features
    brews = [
      # Programming languages
      "kotlin"

      # Version managers (need shell integration for lazy-loading)
      "jenv"
      "nvm"

      # Shell enhancements
      "autojump"

      # Development utilities
      "gh"
    ];

    # Homebrew maintenance settings
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };
}
