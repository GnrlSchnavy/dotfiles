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
      "discord"
      "microsoft-teams"
      "signal"
      "slack"
      "whatsapp"
      #"mattermost"               # No longer used

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
      #"figma"                    # Not currently needed

      # Media
      "jellyfin-media-player"
      "spotify"
      "vlc"

      # Networking & Security
      "nordvpn"
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
    ];

    # CLI Tools (brews) - use when not available in Nix or need Homebrew features
    brews = [
      # Version managers (need shell integration for lazy-loading)
      "jenv"
      "nvm"
      "pyenv"

      # Kubernetes ecosystem
      "fluxcd/tap/flux"
      "helm"
      "kdoctor"
      "kubectl"
      "kubeseal"

      # macOS-specific tools
      "mas"
      "stow"

      # Shell enhancements
      "autojump"
      "tmux"

      # Development utilities
      "gh"
      "pgloader"
      #"sshpass"                  # Prefer SSH keys
      #"bitwarden-cli"            # Using 1password-cli instead
      #"awscli"                   # Not currently working with AWS
    ];

    # Mac App Store apps - only available through App Store
    masApps = {
      "WireGuard" = 1451685025;
      "Windows Remote Desktop" = 1295203466;
    };

    # Homebrew maintenance settings
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };
}
