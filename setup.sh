#!/bin/bash

echo "🚀 installing rosetta"
softwareupdate --install-rosetta

echo "🚀 installing xcode"
xcode-select --install

echo "🚀 Start fetching dotfiles"
# Exit on error and print commands
set -ex

# Temp directory for cloning
TMP_CLONE_DIR=$(mktemp -d)

# Clone the repo (master branch only, no history)
git clone --depth 1 --branch master https://gitlab.com/YvanStemmerik/dotfiles.git "$TMP_CLONE_DIR"

# Create target directory (skip if already exists)
mkdir -p ~/.dotfiles

# Move all files (including hidden) except .git
shopt -s dotglob  # Include hidden files in globbing
mv -f "$TMP_CLONE_DIR"/* ~/.dotfiles/

# Clean up
rm -rf "$TMP_CLONE_DIR"

echo "✅ Dotfiles installed to ~/.dotfiles"

echo "🚀 fetching nix"
sh <(curl -L https://nixos.org/nix/install) --daemon

sudo mkdir -p /etc/nix-darwin
sudo chown $(id -nu):$(id -ng) /etc/nix-darwin
cd /etc/nix-darwin

# To use Nixpkgs unstable:
nix flake init -t nix-darwin/master --extra-experimental-features nix-command --extra-experimental-features flakes
# To use Nixpkgs 24.11:
# nix flake init -t nix-darwin/nix-darwin-24.11

sed -i '' "s/simple/$(scutil --get LocalHostName)/" flake.nix

# To use Nixpkgs unstable:
# nix run nix-darwin/master#darwin-rebuild -- switch
# To use Nixpkgs 24.11:
nix run --extra-experimental-features nix-command --extra-experimental-features flakes nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch
echo "✅ done fetching default nix"

echo "🚀 starting own nix build"
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v

cd ~/.dotfiles
stow .
#maybe do a git init?