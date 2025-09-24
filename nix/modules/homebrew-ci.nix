{ ... }:

{
  homebrew = {
    enable = true;

    # Minimal GUI Applications (casks) - only essential tools for CI testing
    casks = [
      # Essential development tools only
      "intellij-idea"             # JetBrains IDE (has config files to test)
      "visual-studio-code"        # Microsoft editor
      "docker-desktop"            # Docker Desktop (needed for container testing)

      # Essential utilities only
      "rectangle"                 # Window management (small)

      # Essential browser (pick one)
      "brave-browser"             # Privacy-focused browser (faster download than Chrome)
    ];

    # CLI Tools (brews) - keep all CLI tools as they're small and essential for testing
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

    # Mac App Store apps - minimal for CI (skip large apps like Xcode, Outlook)
    masApps = {
      # Skip large applications in CI
      # "Xcode" = 497799835;                # Apple development tools (very large - skip in CI)
      # "Outlook" = 985367838;              # Microsoft email (large - skip in CI)
      # "Windows Remote Desktop" = 1295203466;  # Microsoft RDP (skip in CI)
      "WireGuard" = 1451685025;           # VPN client (small, useful for testing)
    };

    # Homebrew maintenance settings
    onActivation = {
      cleanup = "zap";          # Remove unlisted packages
      autoUpdate = true;        # Update Homebrew automatically
      upgrade = true;           # Upgrade packages automatically
    };
  };
}