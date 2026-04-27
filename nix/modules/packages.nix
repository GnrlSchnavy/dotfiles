{ pkgs, inputs, ... }:

{
  environment.systemPackages = [
    # Nixvim configuration (temporarily disabled while debugging pname issue)
    # inputs.nixvim.packages.${pkgs.system}.default
    pkgs.neovim
    
    # Core development tools (prefer Nix for reproducibility)
    pkgs.git                    # Version control
    pkgs.maven                  # Java build tool

    # Language runtimes are managed by version managers (jenv, nvm, pyenv)
    # not nix, to allow per-project version switching.

    # System utilities (Nix for cross-platform consistency)
    pkgs.tree                   # Directory tree visualization
    pkgs.jq                     # JSON processor
    pkgs.curl                   # HTTP client
    pkgs.wget                   # File downloader
    pkgs.ripgrep               # Fast text search
    pkgs.fd                     # Fast file finder
    pkgs.bat                    # Better cat with syntax highlighting
    
    # Archive and compression
    pkgs.unzip                  # ZIP extraction
    pkgs.p7zip                  # 7zip support
    
    # Development utilities
    pkgs.mkalias                # macOS alias creation
    pkgs.htop                   # Process monitor
    pkgs.fastfetch              # System information

    # Networking
    pkgs.wireguard-tools        # wg / wg-quick CLI for WireGuard tunnels
  ];
}
