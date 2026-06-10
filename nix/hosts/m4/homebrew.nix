{ ... }:

{
  homebrew = {
    enable = true;

    # GUI Applications (casks) - grouped alphabetically within categories
    casks = [
      # Browsers
      "tor-browser"
      "brave-browser"
      "firefox"
      "google-chrome"

      # Communication
      "discord"
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
      "lens"
      "visual-studio-code"
      "warp" # Warp terminal (NOT cloudflare-warp, the VPN)

      # Media
      "jellyfin-media-player"
      "spotify"
      "vlc"

      # Networking & Security
      "proton-drive"
      "proton-mail"
      "proton-mail-bridge"
      "proton-pass"
      "protonvpn"

      # Virtualization & Remote
      "crossover"

      # Programming languages
      "temurin@25"
    ];

    # CLI Tools (brews) - use when not available in Nix or need Homebrew features
    brews = [
      # Programming languages
      "kotlin"

      # Security
      "gnupg"

      # Version managers (need shell integration for lazy-loading)
      "jenv"
      "nvm"

      # Kubernetes ecosystem
      "fluxcd/tap/flux"
      "helm"
      "kdoctor"
      "kubectl"
      "kubeseal"

      # Shell enhancements
      "autojump"
      "tmux"

      # Development utilities
      "gh"
      "stripe-cli"
      "ansible"
    ];

    # Homebrew maintenance settings
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };
}
