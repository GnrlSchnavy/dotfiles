#!/bin/bash

set -e  # Exit on any error

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

echo "🚀 Dotfiles Update Script"
echo "Updating all system components..."
echo

# Change to dotfiles directory
cd ~/.dotfiles || {
    print_error "Could not find ~/.dotfiles directory"
    exit 1
}

# Update Git repository
print_step "Updating dotfiles repository..."
if git pull origin $(git branch --show-current) > /dev/null 2>&1; then
    print_success "Repository updated"
else
    print_warning "Repository update failed or no changes"
fi

# Update Nix flake inputs
print_step "Updating Nix flake inputs..."
if nix flake update nix/ > /dev/null 2>&1; then
    print_success "Nix flake inputs updated"
else
    print_error "Failed to update Nix flake inputs"
fi

# Apply Nix Darwin configuration
print_step "Applying system configuration..."
if darwin-rebuild switch --flake ~/.dotfiles/nix#m4; then
    print_success "System configuration applied"
else
    print_error "Failed to apply system configuration"
    exit 1
fi

# Re-stow dotfiles to ensure symlinks are current
print_step "Updating dotfile symlinks..."
if stow --restow shell git editors development system > /dev/null 2>&1; then
    print_success "Dotfiles symlinked"
else
    print_warning "Some dotfile symlinks may have failed"
fi

# Update Homebrew packages (done automatically by nix-homebrew)
print_step "Homebrew packages updated automatically by nix-homebrew"

# Check for system health
print_step "Running system health checks..."

# Check if essential commands are available
essential_commands=("git" "kubectl" "docker" "stow" "brew")
for cmd in "${essential_commands[@]}"; do
    if command -v "$cmd" > /dev/null 2>&1; then
        echo "  ✅ $cmd available"
    else
        print_warning "$cmd not found in PATH"
    fi
done

print_success "Update complete!"
echo
echo "💡 Next steps:"
echo "  - Restart your terminal for shell changes"
echo "  - Run 'darwin-rebuild switch --flake ~/.dotfiles/nix#m4' manually if there were errors"
echo "  - Check 'brew doctor' if you encounter Homebrew issues"