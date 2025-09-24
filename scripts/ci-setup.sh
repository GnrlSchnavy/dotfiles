#!/bin/bash

# CI-friendly version of setup.sh for automated testing
# This script is designed to run non-interactively in GitLab CI

set -e  # Exit on any error

# Enhanced logging for CI
LOG_FILE="/tmp/ci-setup.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo "🤖 GitLab CI-Friendly Dotfiles Setup Script"
echo "Running automated setup for macOS testing..."
echo "Log file: $LOG_FILE"
echo "Timestamp: $(date)"
echo

# Color codes for output (CI-compatible)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
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

# GitLab CI environment detection and setup
if [[ "$CI" == "true" ]]; then
    print_step "GitLab CI environment detected - configuring for automation"
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_NO_INSTALL_CLEANUP=1
    export HOMEBREW_NO_ANALYTICS=1
    export NONINTERACTIVE=1

    print_step "GitLab CI Environment Info:"
    echo "  Pipeline ID: ${CI_PIPELINE_ID:-unknown}"
    echo "  Job ID: ${CI_JOB_ID:-unknown}"
    echo "  Branch: ${CI_COMMIT_REF_NAME:-unknown}"
    echo "  Project Dir: ${CI_PROJECT_DIR:-$(pwd)}"
fi

# System validation
print_step "Validating system requirements"

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is designed for macOS only!"
    print_error "Current system: $(uname -s)"
    print_error "This may be running on a Linux GitLab runner - macOS runner required"
    exit 1
fi

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    print_step "Detected Apple Silicon (ARM64)"
    NEED_ROSETTA=true
else
    print_step "Detected Intel (x86_64)"
    NEED_ROSETTA=false
fi

print_success "System validation passed"

# Skip Rosetta installation in CI (self-hosted runners should have it)
if [[ "$NEED_ROSETTA" == "true" && "$CI" != "true" ]]; then
    print_step "Installing Rosetta 2 for compatibility..."
    if ! softwareupdate --install-rosetta --agree-to-license; then
        print_warning "Rosetta installation failed or was cancelled"
    else
        print_success "Rosetta 2 installed"
    fi
fi

# Xcode Command Line Tools (should be pre-installed on self-hosted runners)
print_step "Verifying Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
    print_step "Installing Xcode Command Line Tools..."
    # For CI, we'll try to install automatically
    if [[ "$CI" == "true" ]]; then
        # Install CLT if not available
        sudo xcode-select --install || true
        # Wait briefly for installation
        sleep 10
    else
        print_error "Xcode Command Line Tools not found!"
        print_error "Please install manually: xcode-select --install"
        exit 1
    fi

    # Verify installation
    if ! xcode-select -p &> /dev/null; then
        print_error "Xcode Command Line Tools installation failed"
        exit 1
    fi
else
    XCODE_PATH=$(xcode-select -p)
    print_success "Xcode Command Line Tools found at: $XCODE_PATH"
fi

# Set up dotfiles directory (GitLab CI approach)
print_step "Setting up dotfiles directory..."

if [[ "$CI" == "true" ]]; then
    # In GitLab CI, we're already in the repo directory
    TARGET_DIR="$HOME/.dotfiles"
    if [[ ! -d "$TARGET_DIR" ]]; then
        print_step "Creating symlink to current directory for GitLab CI"
        # GitLab CI uses CI_PROJECT_DIR
        WORKSPACE_DIR="${CI_PROJECT_DIR:-$(pwd)}"
        ln -s "$WORKSPACE_DIR" "$TARGET_DIR"
    fi
    print_success "Dotfiles directory prepared for GitLab CI: $TARGET_DIR"
else
    # Original logic for local setup
    REPO_URL="https://gitlab.com/YvanStemmerik/dotfiles.git"
    TARGET_DIR="$HOME/.dotfiles"

    if [ -d "$TARGET_DIR" ]; then
        print_warning "$TARGET_DIR already exists - using existing directory"
    else
        print_step "Cloning dotfiles repository..."
        TEMP_DIR=$(mktemp -d)
        git clone "$REPO_URL" "$TEMP_DIR"
        mv "$TEMP_DIR" "$TARGET_DIR"
        print_success "Dotfiles cloned to $TARGET_DIR"
    fi
fi

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

# Install Homebrew with CI-friendly options
print_step "Installing Homebrew..."
if command -v brew >/dev/null 2>&1; then
    print_success "Homebrew already installed"
else
    print_step "Downloading and installing Homebrew..."
    # Use CI-friendly installation
    export NONINTERACTIVE=1
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for current session
    if [[ "$ARCH" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    print_success "Homebrew installed successfully"
fi

# Verify Homebrew installation
if brew --version >/dev/null 2>&1; then
    BREW_VERSION=$(brew --version | head -1)
    print_success "Homebrew verified: $BREW_VERSION"
else
    print_error "Homebrew installation verification failed"
    exit 1
fi

# Install Nix package manager
print_step "Installing Nix package manager..."
if command -v nix >/dev/null 2>&1; then
    print_success "Nix already installed"
else
    print_step "Downloading and installing Nix..."

    # CI-friendly Nix installation
    if [[ "$CI" == "true" ]]; then
        # Use Determinate Systems installer for better CI support
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    else
        # Standard installation for local use
        sh <(curl -L https://nixos.org/nix/install) --daemon --yes
    fi

    # Source Nix profile
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    print_success "Nix package manager installed"
fi

# Verify Nix installation
if command -v nix >/dev/null 2>&1; then
    NIX_VERSION=$(nix --version | head -1)
    print_success "Nix verified: $NIX_VERSION"
else
    print_error "Nix installation verification failed"
    exit 1
fi

# Install nix-darwin
print_step "Setting up nix-darwin..."
cd "$HOME/.dotfiles"

# Apply nix-darwin configuration
print_step "Applying nix-darwin configuration..."
if [[ "$CI" == "true" ]]; then
    # In GitLab CI, we need to be more careful with the initial bootstrap
    print_step "Bootstrapping nix-darwin in GitLab CI environment..."

    # First time setup requires special handling
    if ! command -v darwin-rebuild >/dev/null 2>&1; then
        print_step "Initial nix-darwin bootstrap..."
        nix run nix-darwin -- switch --flake ~/.dotfiles/nix#m4
    else
        darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v
    fi
else
    # Standard local installation
    nix run nix-darwin -- switch --flake ~/.dotfiles/nix#m4
fi

print_success "nix-darwin configuration applied"

# Set up dotfiles with Stow
print_step "Setting up dotfiles with Stow..."
cd "$HOME/.dotfiles"

# Stow categories
STOW_CATEGORIES=("shell" "git" "editors" "development" "system")

for category in "${STOW_CATEGORIES[@]}"; do
    if [[ -d "$category" ]]; then
        print_step "Stowing $category configuration..."
        if stow "$category" 2>/dev/null; then
            print_success "$category dotfiles linked"
        else
            print_warning "$category stowing had conflicts - attempting to adopt..."
            stow --adopt "$category" 2>/dev/null || print_warning "$category stowing failed"
        fi
    else
        print_warning "$category directory not found"
    fi
done

# Final verification
print_step "Final verification..."

# Test essential commands
essential_commands=("git" "brew" "nix" "stow")
for cmd in "${essential_commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        print_success "$cmd is available"
    else
        print_error "$cmd not found!"
    fi
done

# Test dotfile symlinks
dotfiles=("$HOME/.zprofile" "$HOME/.gitconfig" "$HOME/.ideavimrc")
for file in "${dotfiles[@]}"; do
    if [[ -L "$file" ]]; then
        print_success "$(basename "$file") is properly symlinked"
    else
        print_warning "$(basename "$file") is not symlinked"
    fi
done

print_success "GitLab CI setup completed successfully!"
echo
echo "📋 Setup Summary:"
echo "  - Homebrew: $(brew --version | head -1)"
echo "  - Nix: $(nix --version)"
echo "  - Darwin: $(command -v darwin-rebuild >/dev/null && echo "Available" || echo "Not found")"
echo "  - Dotfiles: $(ls -la ~/.dotfiles | wc -l) items in dotfiles directory"
echo "  - Log file: $LOG_FILE"

if [[ "$CI" == "true" ]]; then
    echo "  - GitLab Pipeline: ${CI_PIPELINE_ID:-unknown}"
    echo "  - GitLab Job: ${CI_JOB_ID:-unknown}"
fi

echo
echo "🎉 Ready for testing!"