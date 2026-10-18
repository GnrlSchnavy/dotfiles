# CLI basics from nixpkgs, on every machine.
{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.git
    pkgs.maven
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
  ];
}
