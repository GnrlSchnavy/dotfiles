# Personal apps from nixpkgs or pinned downloads.
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
    # Music (Jellyfin/Navidrome client)
    feishin
  ];
}
