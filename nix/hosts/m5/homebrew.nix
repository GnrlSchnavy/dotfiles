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
      "microsoft-outlook"
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
      "claude-code"
      "docker-desktop"
      "intellij-idea"
      "visual-studio-code"
      "warp" # Warp terminal (NOT cloudflare-warp, the VPN)

      # Media
      "spotify"

      # Networking & Security
      "proton-drive"
      "proton-mail"
      "proton-mail-bridge"
      "proton-pass"
      "protonvpn"

      # Programming languages
      "temurin@25"
    ];

    # CLI Tools (brews) - use when not available in Nix or need Homebrew features
    brews = [
      # Programming languages
      "kotlin"

      # Security
      # Proton Pass CLI — official tap, not in core Homebrew. brew owns
      # updates (its own `pass-cli update` is disabled under Homebrew);
      # onActivation.upgrade picks up new versions on rebuild.
      "protonpass/tap/pass-cli"

      # Version managers (need shell integration for lazy-loading)
      "jenv"
      "nvm"

      # Shell enhancements
      "autojump"

      # Development utilities
      "uv"
      "gh"
      "kubectl"
      "pnpm"
      "opencode"


    ];

    # Homebrew maintenance settings
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };
}
