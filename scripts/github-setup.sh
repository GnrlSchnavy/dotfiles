#!/bin/bash

# GitHub Actions optimized setup script
# Designed for fresh macOS runners with full system access

set -e  # Exit on any error

echo "🚀 GitHub Actions Dotfiles Setup Script"
echo "Running on fresh macOS environment..."
echo "Timestamp: $(date)"
echo

# Color codes for output
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

# GitHub Actions environment detection
if [[ "$GITHUB_ACTIONS" == "true" ]]; then
    print_step "GitHub Actions environment detected"
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_NO_INSTALL_CLEANUP=1
    export HOMEBREW_NO_ANALYTICS=1
    export NONINTERACTIVE=1

    print_step "GitHub Actions Environment Info:"
    echo "  Workflow: ${GITHUB_WORKFLOW:-unknown}"
    echo "  Run ID: ${GITHUB_RUN_ID:-unknown}"
    echo "  Branch: ${GITHUB_REF_NAME:-unknown}"
    echo "  Workspace: ${GITHUB_WORKSPACE:-$(pwd)}"
fi

# System validation
print_step "Validating system requirements"

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is designed for macOS only!"
    exit 1
fi

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    print_step "Detected Apple Silicon (ARM64)"
elif [[ "$ARCH" == "x86_64" ]]; then
    print_step "Detected Intel (x86_64)"
else
    print_warning "Unknown architecture: $ARCH"
fi

print_success "System validation passed"

# Xcode Command Line Tools (should be available on GitHub runners)
print_step "Verifying Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
    print_error "Xcode Command Line Tools not found!"
    exit 1
else
    XCODE_PATH=$(xcode-select -p)
    print_success "Xcode Command Line Tools found at: $XCODE_PATH"
fi

# Set up dotfiles directory
print_step "Setting up dotfiles directory..."
TARGET_DIR="$HOME/.dotfiles"

if [[ "$GITHUB_ACTIONS" == "true" ]]; then
    # In GitHub Actions, copy from workspace to home
    if [[ -d "$GITHUB_WORKSPACE" && "$GITHUB_WORKSPACE" != "$TARGET_DIR" ]]; then
        print_step "Copying dotfiles from workspace to ~/.dotfiles"
        cp -r "$GITHUB_WORKSPACE" "$TARGET_DIR"
        cd "$TARGET_DIR"
    elif [[ -d "$TARGET_DIR" ]]; then
        cd "$TARGET_DIR"
    else
        print_error "Dotfiles directory not found"
        exit 1
    fi
else
    # Local installation - assume we're already in the right directory
    if [[ ! -d "nix" || ! -f "setup.sh" ]]; then
        print_error "Not in dotfiles directory. Please run from ~/.dotfiles"
        exit 1
    fi
    # Create symlink for local testing
    if [[ "$(pwd)" != "$TARGET_DIR" ]]; then
        ln -sf "$(pwd)" "$TARGET_DIR"
    fi
fi

print_success "Dotfiles directory: $TARGET_DIR"

# Create nix symlink (required for nix-darwin)
SOURCE_DIR="$TARGET_DIR/nix"
SYMLINK_DIR="$HOME/nix"
print_step "Creating Nix symlink: $SOURCE_DIR → $SYMLINK_DIR"
if [[ -L "$SYMLINK_DIR" || -d "$SYMLINK_DIR" ]]; then
    rm -rf "$SYMLINK_DIR"
fi
ln -s "$SOURCE_DIR" "$SYMLINK_DIR"
print_success "Nix symlink created"

# Install Homebrew (fresh install every time in GitHub Actions)
print_step "Installing Homebrew..."
if command -v brew >/dev/null 2>&1; then
    print_success "Homebrew already installed"
    BREW_VERSION=$(brew --version | head -1)
    print_success "Homebrew version: $BREW_VERSION"
else
    print_step "Installing Homebrew from scratch..."
    export NONINTERACTIVE=1
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for current session
    if [[ "$ARCH" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    print_success "Homebrew installed successfully"
    BREW_VERSION=$(brew --version | head -1)
    print_success "Homebrew version: $BREW_VERSION"
fi

# Install Nix package manager
print_step "Installing Nix package manager..."
if command -v nix >/dev/null 2>&1; then
    print_success "Nix already installed"
    NIX_VERSION=$(nix --version | head -1)
    print_success "Nix version: $NIX_VERSION"
else
    print_step "Installing Nix with Determinate Systems installer..."

    # Use Determinate Systems installer (better for CI)
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

    # Source Nix profile
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    print_success "Nix package manager installed"
    NIX_VERSION=$(nix --version | head -1)
    print_success "Nix version: $NIX_VERSION"
fi

# Apply nix-darwin configuration
print_step "Setting up nix-darwin..."
cd "$TARGET_DIR"

print_step "Validating Nix configuration...")
if nix flake check ./nix; then
    print_success "Nix flake configuration is valid"
else
    print_error "Nix flake configuration has errors"
    exit 1
fi

if [[ "$GITHUB_ACTIONS" == "true" ]]; then
    # In GitHub Actions, we can actually run the full system activation
    print_step "Applying nix-darwin configuration (full system activation)...")

    # First time setup
    if ! command -v darwin-rebuild >/dev/null 2>&1; then
        print_step "Initial nix-darwin bootstrap..."
        nix run nix-darwin -- switch --flake ./nix#m4
    else
        darwin-rebuild switch --flake ./nix#m4
    fi

    print_success "nix-darwin configuration applied successfully"
else
    # Local testing - just validate
    print_step "Validating nix-darwin configuration (local mode)..."
    if nix build ./nix#darwinConfigurations.m4.system --no-link; then
        print_success "Darwin configuration builds successfully"
    else
        print_error "Darwin configuration failed to build"
        exit 1
    fi
fi

# Set up dotfiles with Stow
print_step "Setting up dotfiles with Stow..."

# Ensure stow is available
if ! command -v stow >/dev/null 2>&1; then
    print_step "Installing GNU Stow..."
    brew install stow
fi

# Stow categories
STOW_CATEGORIES=("shell" "git" "editors" "development" "system")

for category in "${STOW_CATEGORIES[@]}"; do
    if [[ -d "$category" ]]; then
        print_step "Stowing $category configuration..."
        if stow "$category"; then
            print_success "$category dotfiles linked"
        else
            print_warning "$category stowing had conflicts - attempting to adopt..."
            stow --adopt "$category" || print_warning "$category stowing failed"
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
        exit 1
    fi
done

# Test dotfile symlinks
dotfiles=("$HOME/.zprofile" "$HOME/.gitconfig")
for file in "${dotfiles[@]}"; do
    if [[ -L "$file" ]]; then
        print_success "$(basename "$file") is properly symlinked"
    else
        print_warning "$(basename "$file") is not symlinked"
    fi
done

print_success "Setup completed successfully!"
echo
echo "📋 Setup Summary:"
echo "  - macOS: $(sw_vers -productVersion) ($(uname -m))"
echo "  - Homebrew: $(brew --version | head -1)"
echo "  - Nix: $(nix --version)"
echo "  - Darwin: $(command -v darwin-rebuild >/dev/null && echo "Available" || echo "Not available")"
echo "  - Dotfiles: $(ls -la ~/.dotfiles | wc -l) items in ~/.dotfiles"

if [[ "$GITHUB_ACTIONS" == "true" ]]; then
    echo "  - GitHub Workflow: ${GITHUB_WORKFLOW:-unknown}"
    echo "  - GitHub Run: ${GITHUB_RUN_ID:-unknown}"
fi

echo
echo "🎉 Fresh macOS environment setup complete!"