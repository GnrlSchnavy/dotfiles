#!/bin/bash

set -e  # Exit on any error

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
REPO_URL="https://gitlab.com/YvanStemmerik/dotfiles.git"
TARGET_DIR="$HOME/.dotfiles"

if [ -d "$TARGET_DIR" ]; then
    print_error "$TARGET_DIR already exists."
    print_warning "Please remove or backup the existing directory before running this script."
    exit 1
fi

TEMP_DIR=$(mktemp -d)
print_step "Cloning repository to temporary location: $TEMP_DIR"
git clone "$REPO_URL" "$TEMP_DIR"

print_step "Moving repository to $TARGET_DIR"
mv "$TEMP_DIR" "$TARGET_DIR"
print_success "Dotfiles successfully installed to $TARGET_DIR"

# Create nix symlink (required for nix-darwin)
SOURCE_DIR="$HOME/.dotfiles/nix"
SYMLINK_DIR="$HOME/nix"
print_step "Creating Nix symlink: $SOURCE_DIR → $SYMLINK_DIR"
if [ -L "$SYMLINK_DIR" ] || [ -d "$SYMLINK_DIR" ]; then
    print_warning "Removing existing $SYMLINK_DIR"
    rm -rf "$SYMLINK_DIR"
fi
ln -s "$SOURCE_DIR" "$SYMLINK_DIR"
print_success "Nix symlink created"

# Install Homebrew (required for nix-homebrew integration)
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
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    print_success "Nix package manager installed"
else
    print_success "Nix package manager already installed"
fi

# Install nix-darwin
print_step "Setting up nix-darwin..."
sudo mkdir -p /etc/nix-darwin
sudo chown $(id -nu):$(id -ng) /etc/nix-darwin

# Get hostname for configuration
HOSTNAME=$(scutil --get LocalHostName)
print_step "Detected hostname: $HOSTNAME"

# Check if we need to use 'm4' configuration or create host-specific one
if [ "$HOSTNAME" != "m4" ]; then
    print_warning "Hostname '$HOSTNAME' doesn't match 'm4' configuration"
    print_warning "Using 'm4' configuration anyway - you may want to customize later"
fi

cd /etc/nix-darwin
nix flake init -t nix-darwin/master --extra-experimental-features nix-command --extra-experimental-features flakes
sed -i '' "s/simple/$HOSTNAME/" flake.nix

print_step "Building initial nix-darwin configuration..."
nix run --extra-experimental-features nix-command --extra-experimental-features flakes nix-darwin/master#darwin-rebuild -- switch
print_success "Initial nix-darwin setup complete"

# Apply custom nix-darwin configuration
print_step "Applying custom nix-darwin configuration..."
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v
print_success "Custom nix-darwin configuration applied"

# Set up dotfiles with Stow
print_step "Setting up dotfiles with Stow..."
cd ~/.dotfiles

# Install stow if not available (should be installed by Homebrew via Nix)
if ! command -v stow &> /dev/null; then
    print_error "Stow not found! Please check nix-darwin configuration."
    exit 1
fi

# Stow all categories
print_step "Stowing dotfile categories..."
stow shell
stow editors  
stow development
stow system

print_success "All dotfiles stowed successfully"

# Set up Claude Code configuration
print_step "Setting up Claude Code configuration..."
if [ -f ~/.claude/settings.local.json ]; then
    print_success "Claude Code configuration ready"
else
    print_warning "Claude Code configuration not found - you may need to install Claude Code first"
fi

# Final verification
print_step "Performing final verification..."

# Check if shell profile loads correctly
if [ -f ~/.zprofile ]; then
    print_success "Shell profile (.zprofile) configured"
else
    print_error "Shell profile not found"
fi

# Check if Homebrew integration works
if command -v brew &> /dev/null; then
    print_success "Homebrew integration working"
else
    print_warning "Homebrew not in PATH - may need to restart shell"
fi

# Check if Nix commands work
if command -v nix &> /dev/null; then
    print_success "Nix commands available"
else
    print_warning "Nix not in PATH - may need to restart shell"
fi

echo
print_success "🎉 Dotfiles setup complete!"
echo
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zprofile"
echo "2. Install Claude Code if you haven't already"
echo "3. Verify all applications are working correctly"
echo "4. Customize any settings as needed"
echo
echo "Configuration files are located in ~/.dotfiles/"
echo "Documentation available in ~/.dotfiles/CLAUDE.md"
echo
print_success "Happy coding! 🚀"