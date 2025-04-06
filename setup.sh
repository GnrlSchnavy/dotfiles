#!/bin/bash

echo "🚀 installing rosetta"
softwareupdate --install-rosetta

echo "🚀 installing xcode"
xcode-select --install

echo "🚀 Start fetching dotfiles"

set -ex
TMP_CLONE_DIR=$(mktemp -d)
git clone --depth 1 --branch master https://gitlab.com/YvanStemmerik/dotfiles.git "$TMP_CLONE_DIR"
mkdir -p ~/.dotfiles
(
  shopt -s dotglob
  mv -f "$TMP_CLONE_DIR"/* ~/.dotfiles/
)
rm -rf "$TMP_CLONE_DIR"

echo "✅ Dotfiles installed to ~/.dotfiles"

SOURCE_DIR="$HOME/.dotfiles/nix"
TARGET_DIR="$HOME/nix"
echo "🔗 Symlinking $SOURCE_DIR → $TARGET_DIR"
ln -s "$SOURCE_DIR" "$TARGET_DIR"


echo "🚀 fetching nix"
sh <(curl -L https://nixos.org/nix/install) --daemon

sudo mkdir -p /etc/nix-darwin
sudo chown $(id -nu):$(id -ng) /etc/nix-darwin
cd /etc/nix-darwin

nix flake init -t nix-darwin/master --extra-experimental-features nix-command --extra-experimental-features flakes
sed -i '' "s/simple/$(scutil --get LocalHostName)/" flake.nix

nix run --extra-experimental-features nix-command --extra-experimental-features flakes nix-darwin/master#darwin-rebuild -- switch
echo "✅ done fetching default nix"

echo "🚀 starting own nix build"
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v

cd ~/.dotfiles
stow .
#maybe do a git init?