#!/bin/bash

echo "🚀 installing rosetta"
softwareupdate --install-rosetta

echo "🚀 installing xcode"
xcode-select --install

echo "🚀 Start fetching dotfiles"

REPO_URL="https://gitlab.com/YvanStemmerik/dotfiles.git"
TARGET_DIR="$HOME/.dotfiles"
if [ -d "$TARGET_DIR" ]; then
    echo "Error: $TARGET_DIR already exists."
    echo "Please remove or backup the existing directory before running this script."
    exit 1
fi
TEMP_DIR=$(mktemp -d)
echo "Cloning repository to temporary location: $TEMP_DIR"
git clone "$REPO_URL" "$TEMP_DIR"

echo "Moving repository to $TARGET_DIR"
mv "$TEMP_DIR" "$TARGET_DIR"

echo "✅ Dotfiles successfully installed to $TARGET_DIR"

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