{ pkgs, inputs, ... }:

{
  environment.systemPackages = [
    # Nixvim configuration
    inputs.nixvim.packages.${pkgs.system}.default
    
    # Core development tools (prefer Nix for reproducibility)
    pkgs.git                    # Version control
    pkgs.maven                  # Java build tool
    pkgs.rustc                  # Rust compiler
    
    # Container ecosystem
    # pkgs.docker               # Docker CLI - provided by Docker Desktop
    # pkgs.docker-compose       # Container orchestration - provided by Docker Desktop  
    
    # Language runtimes and compilers
    pkgs.zulu23                 # Java 23 JDK
    pkgs.python3                # Python runtime
    
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
  ];
}