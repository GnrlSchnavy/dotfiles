#!/bin/bash

set -euo pipefail

echo "🚀 macOS Dotfiles Setup Script"
echo "Setting up development environment from scratch..."
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}🚀 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is designed for macOS only!"
    exit 1
fi

# Check if running on Apple Silicon
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    print_step "Detected Apple Silicon (ARM64)"
    NEED_ROSETTA=true
else
    print_step "Detected Intel (x86_64)"
    NEED_ROSETTA=false
fi

# Install Rosetta 2 (for Apple Silicon)
if [[ "$NEED_ROSETTA" == "true" ]]; then
    print_step "Installing Rosetta 2 for compatibility..."
    if ! softwareupdate --install-rosetta --agree-to-license; then
        print_warning "Rosetta installation failed or was cancelled"
    else
        print_success "Rosetta 2 installed"
    fi
fi

# Install Xcode Command Line Tools
print_step "Installing Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
    xcode-select --install
    print_warning "Please complete Xcode Command Line Tools installation in the popup, then run this script again"
    exit 1
else
    print_success "Xcode Command Line Tools already installed"
fi

# Clone dotfiles repository
print_step "Cloning dotfiles repository..."
REPO_URL="https://github.com/GnrlSchnavy/dotfiles.git"
TARGET_DIR="$HOME/.dotfiles"

if [ -d "$TARGET_DIR" ]; then
    print_warning "$TARGET_DIR already exists; skipping clone."
else
    git clone "$REPO_URL" "$TARGET_DIR"
    print_success "Dotfiles cloned to $TARGET_DIR"
fi

# Detect host and verify a host descriptor exists for it.
# nix/hosts/<hostname>/default.nix must exist before running setup.
# To onboard a new Mac, copy nix/hosts/template/ to nix/hosts/<your-hostname>/,
# edit username/hostname, register it in nix/flake.nix's hosts attrset, and
# commit before running this script.
HOSTNAME=$(scutil --get LocalHostName)
HOST_DESCRIPTOR="$TARGET_DIR/nix/hosts/$HOSTNAME/default.nix"
print_step "Detected hostname: $HOSTNAME"

if [ ! -f "$HOST_DESCRIPTOR" ]; then
    print_error "No host descriptor at $HOST_DESCRIPTOR"
    echo
    echo "Before running setup, create a host descriptor for this machine:"
    echo "  1. cp -r $TARGET_DIR/nix/hosts/template $TARGET_DIR/nix/hosts/$HOSTNAME"
    echo "  2. Edit $TARGET_DIR/nix/hosts/$HOSTNAME/default.nix — set username, etc."
    echo "  3. Register it in $TARGET_DIR/nix/flake.nix under the hosts attrset:"
    echo "       hosts = {"
    echo "         m4 = import ./hosts/m4;"
    echo "         $HOSTNAME = import ./hosts/$HOSTNAME;"
    echo "       };"
    echo "  4. git add the new files (nix flakes only see git-tracked content)"
    echo "  5. Re-run ./setup.sh"
    exit 1
fi
print_success "Host descriptor found at $HOST_DESCRIPTOR"

# Install Homebrew (used as nix-homebrew's package source).
# nix-homebrew patches Homebrew at activation, but it still needs an
# initial install to take over.
print_step "Installing Homebrew..."
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for current session
    if [[ "$ARCH" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    print_success "Homebrew installed"
else
    print_success "Homebrew already installed"
fi

# Install Nix package manager
print_step "Installing Nix package manager..."
if ! command -v nix &> /dev/null; then
    sh <(curl -L https://nixos.org/nix/install) --daemon

    # Source Nix for current session
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        # shellcheck disable=SC1091
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    print_success "Nix package manager installed"
else
    print_success "Nix package manager already installed"
fi

# Install nix-darwin and apply our flake in one step.
# Pin to the same nix-darwin release that flake.nix uses to avoid
# bootstrapping with a different version. sudo because nix-darwin's
# activation step requires root.
print_step "Bootstrapping nix-darwin and applying configuration for $HOSTNAME..."
sudo nix run \
    --extra-experimental-features "nix-command flakes" \
    "github:LnL7/nix-darwin/nix-darwin-25.11#darwin-rebuild" -- \
    switch --flake "$TARGET_DIR/nix#$HOSTNAME"
print_success "nix-darwin configuration applied"

# Final verification
print_step "Performing final verification..."

if command -v darwin-rebuild &> /dev/null; then
    print_success "darwin-rebuild available — future rebuilds: darwin-rebuild switch --flake ~/.dotfiles/nix#$HOSTNAME"
else
    print_warning "darwin-rebuild not in PATH — restart your shell"
fi

if [ -L ~/.zshrc ]; then
    print_success "Shell config (~/.zshrc) managed by home-manager"
else
    print_warning "~/.zshrc is not a symlink — home-manager activation may have failed"
fi

if command -v brew &> /dev/null; then
    print_success "Homebrew integration working"
else
    print_warning "Homebrew not in PATH — restart your shell"
fi

echo
print_success "🎉 Dotfiles setup complete!"
echo
echo "Next steps:"
echo "1. Restart your terminal so PATH and home-manager-managed files take effect"
echo "2. Bootstrap language toolchains (jenv/nvm/pyenv install only the binaries,"
echo "   not actual language versions):"
echo "     jenv add /Library/Java/JavaVirtualMachines/temurin-25.jdk/Contents/Home"
echo "     jenv global temurin-25  # adjust to whichever JDK you installed"
echo "     nvm install --lts"
echo "     pyenv install 3.13"
echo "     pyenv global 3.13"
echo
echo "Configuration: ~/.dotfiles/"
echo "Documentation: ~/.dotfiles/CLAUDE.md"
echo
print_success "Happy coding! 🚀"
