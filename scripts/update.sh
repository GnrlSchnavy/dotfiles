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

HOSTNAME="${DOTFILES_HOST:-$(scutil --get LocalHostName)}"
FLAKE="$HOME/.dotfiles/nix#$HOSTNAME"

if ! git diff --quiet -- nix/flake.lock; then
    print_error "nix/flake.lock has uncommitted changes — commit or discard them first"
    exit 1
fi

# Update Git repository
print_step "Pulling latest from origin..."
before="$(git rev-parse HEAD)"
if git pull --ff-only origin "$(git branch --show-current)"; then
    print_success "Repository updated"
else
    print_error "Pull failed (uncommitted changes? diverged from origin?) — fix that, then re-run"
    exit 1
fi

# What was pulled runs as root below, so it gets a look first. Declining
# rewinds the pull: the next run shows the same commits again.
if [ "$(git rev-parse HEAD)" != "$before" ]; then
    print_step "New commits (applied as root below):"
    git --no-pager log --stat --format='%n%C(yellow)%h%C(reset) %an, %ar: %s' "$before..HEAD"
    echo
    read -r -p "Apply these commits? [y/N] " answer || answer=""
    if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
        git reset -q --keep "$before"
        print_warning "Not applied; the pull was undone"
        exit 1
    fi
fi

# Inputs aren't bumped here: master only takes PRs, so newer inputs arrive
# through the weekly lock-update PR (or Actions → update flake.lock → Run
# workflow), tested by CI before any Mac runs them.

# Build first: a failure here changes nothing on the machine.
print_step "Building the configuration for $HOSTNAME (nothing applied yet)..."
if ! darwin-rebuild build --flake "$FLAKE"; then
    print_error "Build failed — nothing applied"
    exit 1
fi
rm -f result

# Apply nix-darwin (also activates home-manager)
print_step "Applying system configuration for $HOSTNAME..."
if sudo darwin-rebuild switch --flake "$FLAKE"; then
    print_success "System configuration applied"
else
    print_error "Switch failed (roll back: sudo darwin-rebuild --rollback)"
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
