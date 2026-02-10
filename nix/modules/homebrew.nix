{ ... }:

{
  homebrew = {
    enable = true;
    
    # GUI Applications (casks) - prefer for macOS native apps
    casks = [
      # Development environments
      "intellij-idea"             # JetBrains IDE
      "visual-studio-code"        # Microsoft editor
      
      # Browsers
      "google-chrome"             # Google browser
      "brave-browser"             # Privacy-focused browser
      "firefox"
      
      # Communication and collaboration
      "slack"                     # Team communication
      "discord"                   # Gaming/community chat
      "whatsapp"                  # Messaging
      "signal"                    # Secure messaging
      #"mattermost"                # Enterprise chat
      
      # Productivity and utilities
      "alfred"                    # Application launcher
      "rectangle"                 # Window management
      "1password"                 # Password manager
      "1password-cli"             # 1Password command line (cask)
      "obsidian"                  # Note-taking

      # Media and entertainment
      "spotify"                   # Music streaming
      "vlc"                       # Media player
      "jellyfin-media-player"
      
      # Development tools (GUI)
      "docker-desktop"            # Docker Desktop (GUI + CLI)
      "postman"                   # API testing
      "bruno"                     # API testing alternative
      "cyberduck"                 # FTP/cloud storage
      
      # Design and creativity
      #"figma"                     # Design tool
      
      # System and network tools
      "nordvpn"                   # VPN service
      "warp"                      # Cloudflare WARP
      
      # Virtualization and remote access
      "crossover"                 # Windows compatibility
      "nvidia-geforce-now"        # Geforce Now Gaming
      "teamviewer"                # Remote access
      
      # Temporary/project-specific
      "lens"                      # Kubernetes GUI
      "claude"                    # Claude AI assistant
      
      # Random dev tools 
      "chromedriver"              # Chrome WebDriver for automation

      # Proton
      "proton-mail"
      "proton-mail-bridge"
      "protonvpn"
      "proton-drive"
      "proton-pass"
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
      #"sshpass"                   # SSH password authentication (prefer SSH keys)
      "pgloader"                  # PostgreSQL data loading
      #"bitwarden-cli"             # Bitwarden password manager CLI
      
      # Development utilities not in Nix or outdated
      "gh"                        # GitHub CLI
      #"awscli"                    # AWS command line (correct name)
    ];
    
    # Mac App Store apps - only available through App Store
    masApps = {
      "WireGuard" = 1451685025;           # VPN client
      "Outlook" = 985367838;              # Microsoft email
      "Windows Remote Desktop" = 1295203466;  # Microsoft RDP
      "TestFlight" = 899247664;           # Beta app testing
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
