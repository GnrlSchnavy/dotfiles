{ pkgs, ... }:

let
  # nixpkgs' feishin builds from source with electron-builder and fails on
  # Darwin (needs Apple's codesign, absent in the Nix build). Wrap the
  # official dmg instead — pinned, declarative, lands in Nix Apps.
  feishin = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "feishin";
    version = "1.15.1";
    src = pkgs.fetchurl {
      url = "https://github.com/jeffvli/feishin/releases/download/v${version}/Feishin-${version}-mac-arm64.dmg";
      hash = "sha256-tkoqVIInq4JC3FxXCAeg1hCFrth808TjfkCjVDLRrCw=";
    };
    nativeBuildInputs = [ pkgs.undmg ];
    sourceRoot = ".";
    installPhase = ''
      mkdir -p $out/Applications
      cp -R Feishin.app $out/Applications/
    '';
  };
in
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

    # Music
    feishin
  ];
}
