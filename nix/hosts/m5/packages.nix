{ pkgs, ... }:

{
  # Note: nvim is added per-host in flake.nix (mkNvim) so flakePath/
  # darwinHost can be parameterized.
  environment.systemPackages = [
    # Core development tools
    pkgs.git
    pkgs.maven

    # Language runtimes are managed by version managers (jenv, nvm, pyenv)
    # not nix, to allow per-project version switching.

    # System utilities
    pkgs.tree
    pkgs.jq
    pkgs.curl
    pkgs.wget
    pkgs.ripgrep
    pkgs.fd
    pkgs.bat

    # Archive and compression
    pkgs.unzip
    pkgs.p7zip

    # Development utilities
    pkgs.mkalias
    pkgs.htop
    pkgs.fastfetch

    # Networking
    pkgs.wireguard-tools  # wg / wg-quick CLI for WireGuard tunnels
  ];
}
