# CLI tools from nixpkgs, on every machine — the default source for CLI
# tools (docs/packages.md). The few that stay in Homebrew say why in
# homebrew.nix.
{ pkgs, ... }:

{
  environment.systemPackages = [
    # Basics
    pkgs.git
    pkgs.tree
    pkgs.jq
    pkgs.curl
    pkgs.wget
    pkgs.ripgrep
    pkgs.fd
    pkgs.bat
    pkgs.unzip
    pkgs.p7zip
    pkgs.mkalias
    pkgs.htop
    pkgs.fastfetch

    # Shell (directory jumping is zoxide, from home-manager)
    pkgs.tmux

    # Security
    pkgs.gnupg

    # JVM and JS tooling (the JDKs and Node themselves come from mise)
    pkgs.maven
    pkgs.kotlin
    pkgs.kdoctor # Kotlin Multiplatform environment check
    pkgs.pnpm

    # Kubernetes (flux stays in Homebrew, see homebrew.nix)
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.kubeseal

    # GitHub
    pkgs.gh
  ];
}
