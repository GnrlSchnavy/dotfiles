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
      "1password"
      "1password-cli"
      "alfred"
      "obsidian"
      "rectangle"

      # Development
      "bruno"
      "chromedriver"
      "claude"
      "cyberduck"
      "docker-desktop"
      "intellij-idea"
      "lens"
      "postman"
      "visual-studio-code"

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
      "warp"

      # Virtualization & Remote
      "crossover"
      "nvidia-geforce-now"
      "teamviewer"

      # Programming languages
      "temurin@25"
    ];

    # CLI Tools (brews) - use when not available in Nix or need Homebrew features
    brews = [
      # Programming languages
      "kotlin"
      "python-tk"

      # Security
      "gnupg"
      "tor"

      # Version managers (need shell integration for lazy-loading)
      "jenv"
      "nvm"
      "pipx"
      "pyenv"

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
      "pgloader"
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
