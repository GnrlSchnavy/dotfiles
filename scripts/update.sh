#!/bin/bash

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step()    { echo -e "${BLUE}🔄 $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }

echo "🚀 Dotfiles Update Script"
echo

cd ~/.dotfiles || { print_error "Could not find ~/.dotfiles"; exit 1; }

HOSTNAME=$(scutil --get LocalHostName)

# Update Git repository
print_step "Pulling latest from origin..."
if git pull --ff-only origin "$(git branch --show-current)" > /dev/null 2>&1; then
    print_success "Repository updated"
else
    print_warning "Pull failed (uncommitted changes? non-fast-forward?)"
fi

# Update Nix flake inputs
print_step "Updating Nix flake inputs..."
if nix flake update --flake ./nix > /dev/null 2>&1; then
    print_success "Flake inputs updated"
else
    print_error "Failed to update flake inputs"
    exit 1
fi

# Apply nix-darwin (also activates home-manager)
print_step "Applying system configuration for $HOSTNAME..."
if sudo darwin-rebuild switch --flake "$HOME/.dotfiles/nix#$HOSTNAME"; then
    print_success "System configuration applied"
else
    print_error "Rebuild failed"
    exit 1
fi

# Sanity check
print_step "Verifying essential tools..."
for cmd in git brew nix darwin-rebuild; do
    if command -v "$cmd" > /dev/null 2>&1; then
        echo "  ✅ $cmd"
    else
        print_warning "$cmd not on PATH"
    fi
done

print_success "Update complete."
echo
echo "💡 Restart your terminal to pick up shell changes."
