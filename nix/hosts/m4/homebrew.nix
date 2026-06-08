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

      # Programming languages
      "temurin@25"

      #Gaming
      "crossover"
      "steam"
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

      # AI tooling runtimes — pinned here (not via nvm/pyenv) because
      # claude-mem needs them present at machine scope: bun runs its
      # worker daemon, uv backs its Python vector search. claude-mem
      # would otherwise auto-fetch unpinned copies on first install.
      "oven-sh/bun/bun"
      "uv"
    ];

    # Homebrew maintenance settings
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };
}
