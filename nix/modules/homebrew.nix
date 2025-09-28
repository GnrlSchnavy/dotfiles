{ ... }:

{
  homebrew = {
    enable = true;
    
    # GUI Applications (casks) - prefer for macOS native apps
    casks = [
      # Development environments
      "intellij-idea"             # JetBrains IDE
      "visual-studio-code"        # Microsoft editor
      "android-studio"            # Android development
      
      # Browsers
      "google-chrome"             # Google browser
      "brave-browser"             # Privacy-focused browser
      
      # Communication and collaboration
      "slack"                     # Team communication
      "discord"                   # Gaming/community chat
      "whatsapp"                  # Messaging
      "signal"                    # Secure messaging

      # Productivity and utilities
      "1password"                 # Password manager
      "1password-cli"             # 1Password command line (cask)
      "alfred"                    # Application launcher
      "rectangle"                 # Window management
      "bitwarden"                 # Password manager (alternative)
      "obsidian"                  # Note-taking

      # Media and entertainment
      "spotify"                   # Music streaming
      "vlc"                       # Media player
      
      # Development tools (GUI)
      "docker-desktop"            # Docker Desktop (GUI + CLI)
      "postman"                   # API testing
      "bruno"                     # API testing alternative
      "cyberduck"                 # FTP/cloud storage
      
      # System and network tools
      "nordvpn"                   # VPN service
      "warp"                      # Cloudflare WARP
      
      # Virtualization and remote access
      "crossover"                 # Windows compatibility

      # Temporary/project-specific
      "lens"                      # Kubernetes GUI
      "claude"                    # Claude AI assistant
      
      # Random dev tools
      "chromedriver"              # Chrome WebDriver for automation
    ];
    
    # CLI Tools (brews) - use when not available in Nix or need Homebrew features
    brews = [
      # Version and environment managers (need shell integration)
      "pyenv"                     # Python version manager
      "nvm"                       # Node version manager  
      "jenv"                      # Java version manager
      
      # Kubernetes ecosystem (specialized tools/taps)
      "helm"                      # Kubernetes package manager
      "kubectl"                   # Kubernetes CLI
      "kubeseal"                  # Sealed secrets
      "fluxcd/tap/flux"           # GitOps tool (requires tap)
      "kdoctor"                   # Kubernetes diagnostics
      
      # macOS-specific tools
      "mas"                       # Mac App Store CLI
      "stow"                      # Symlink farm manager (better macOS integration)
      
      # Shell enhancements
      "autojump"                  # Smart directory jumping
      "tmux"                      # Terminal multiplexer
      
      # Specialized CLI tools
      "sshpass"                   # SSH password authentication
      "pgloader"                  # PostgreSQL data loading
      "bitwarden-cli"             # Bitwarden password manager CLI
      
      # Development utilities not in Nix or outdated
      "gh"                        # GitHub CLI
    ];
    
    # Mac App Store apps - only available through App Store
    masApps = {
      "WireGuard" = 1451685025;           # VPN client
      "Outlook" = 985367838;              # Microsoft email
      "Windows Remote Desktop" = 1295203466;  # Microsoft RDP
      "Xcode" = 497799835;                # Apple development tools
    };
    
    # Homebrew maintenance settings
    onActivation = {
      cleanup = "zap";          # Remove unlisted packages
      autoUpdate = true;        # Update Homebrew automatically
      upgrade = true;           # Upgrade packages automatically
    };
  };
}
