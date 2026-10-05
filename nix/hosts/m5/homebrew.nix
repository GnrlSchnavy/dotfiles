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
      "tor-browser"

      # Communication
      "discord"
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
      "lens"
      "visual-studio-code"
      "warp" 

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

      # AI
      "github-copilot-app"
      "wispr-flow"

      #VPN
      "tailscale-app"

      #Games
      "crossover"
      "steam"

      #Utilities
      "balenaetcher"
      "taskexplorer"
      "knockknock"
      "little-snitch"
      "oversight"

    ];


    # CLI Tools (brews) - use when not available in Nix or need Homebrew features
    brews = [
      # Programming languages
      "kotlin"

      # Security
      "gnupg"
      # Proton Pass CLI — official tap, not in core Homebrew. brew owns
      # updates (its own `pass-cli update` is disabled under Homebrew);
      # onActivation.upgrade picks up new versions on rebuild.
      "protonpass/tap/pass-cli"

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
      "ansible"
      "gh"
      "opencode"
      "openspec"
      "pnpm"
      "stripe-cli"

      # Utilities
      "clamav"
      "nmap"
    ];

    # Homebrew maintenance settings
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };
}
