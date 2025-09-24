#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_section() {
    echo -e "${BLUE}🔍 $1${NC}"
}

print_success() {
    echo -e "  ${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "  ${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "  ${RED}❌ $1${NC}"
}

print_info() {
    echo -e "  ℹ️  $1"
}

echo "🔍 Dotfiles Health Check"
echo "Verifying system configuration and setup..."
echo

# Check if we're in the right directory
print_section "Repository Status"
if [ -d "$HOME/.dotfiles" ]; then
    cd "$HOME/.dotfiles" || exit 1
    print_success "Dotfiles directory found"

    if git rev-parse --git-dir > /dev/null 2>&1; then
        print_success "Git repository is valid"

        # Check for uncommitted changes
        if git diff --quiet && git diff --cached --quiet; then
            print_success "Working directory is clean"
        else
            print_warning "Uncommitted changes detected"
            print_info "Run 'git status' to see changes"
        fi

        # Check current branch
        BRANCH=$(git branch --show-current)
        print_info "Current branch: $BRANCH"
    else
        print_error "Not a valid Git repository"
    fi
else
    print_error "Dotfiles directory not found at ~/.dotfiles"
    exit 1
fi

# Check Nix configuration
print_section "Nix Configuration"
if command -v nix > /dev/null 2>&1; then
    print_success "Nix package manager installed"

    if command -v darwin-rebuild > /dev/null 2>&1; then
        print_success "Nix Darwin available"

        # Check flake configuration
        if nix flake check nix/ > /dev/null 2>&1; then
            print_success "Flake configuration is valid"
        else
            print_error "Flake configuration has issues"
            print_info "Run 'nix flake check nix/' for details"
        fi
    else
        print_error "Nix Darwin not found"
    fi
else
    print_error "Nix package manager not installed"
fi

# Check Homebrew
print_section "Homebrew Configuration"
if command -v brew > /dev/null 2>&1; then
    print_success "Homebrew installed"

    # Check homebrew doctor
    if brew doctor > /dev/null 2>&1; then
        print_success "Homebrew health check passed"
    else
        print_warning "Homebrew has issues"
        print_info "Run 'brew doctor' for details"
    fi
else
    print_error "Homebrew not installed"
fi

# Check Stow setup
print_section "Stow Configuration"
if command -v stow > /dev/null 2>&1; then
    print_success "GNU Stow available"

    # Check for stow conflicts
    categories=("shell" "git" "editors" "development" "system")
    conflicts_found=false

    for category in "${categories[@]}"; do
        if [ -d "$category" ]; then
            if stow --no-folding --dry-run "$category" > /dev/null 2>&1; then
                print_success "$category category ready"
            else
                print_warning "$category has stow conflicts"
                conflicts_found=true
            fi
        else
            print_warning "$category directory not found"
        fi
    done

    if [ "$conflicts_found" = true ]; then
        print_info "Run 'stow --adopt <category>' to resolve conflicts"
    fi
else
    print_error "GNU Stow not found"
fi

# Check symlinks
print_section "Symlink Status"
dotfiles=(
    "$HOME/.zprofile"
    "$HOME/.zshrc"
    "$HOME/.gitconfig"
    "$HOME/.gitignore_global"
    "$HOME/.ideavimrc"
    "$HOME/.claude"
)

for file in "${dotfiles[@]}"; do
    if [ -L "$file" ]; then
        if [ -e "$file" ]; then
            print_success "$(basename "$file") symlinked correctly"
        else
            print_error "$(basename "$file") is broken symlink"
        fi
    elif [ -e "$file" ]; then
        print_warning "$(basename "$file") exists but is not symlinked"
        print_info "Consider running 'stow --adopt <category>'"
    else
        print_warning "$(basename "$file") not found"
    fi
done

# Check essential tools
print_section "Essential Tools"
essential_tools=(
    "git:Git version control"
    "kubectl:Kubernetes CLI"
    "docker:Container runtime"
    "nvim:Neovim editor"
    "code:Visual Studio Code"
)

for tool_desc in "${essential_tools[@]}"; do
    IFS=':' read -ra ADDR <<< "$tool_desc"
    tool="${ADDR[0]}"
    desc="${ADDR[1]}"

    if command -v "$tool" > /dev/null 2>&1; then
        print_success "$desc available"
    else
        print_warning "$desc not found"
    fi
done

# Check environment
print_section "Environment"
if [ -n "$NVM_DIR" ]; then
    print_success "NVM configured"
else
    print_warning "NVM not configured"
fi

if command -v jenv > /dev/null 2>&1; then
    print_success "jenv available for Java version management"
else
    print_warning "jenv not available"
fi

# System information
print_section "System Information"
print_info "macOS version: $(sw_vers -productVersion)"
print_info "Architecture: $(uname -m)"
print_info "Shell: $SHELL"
print_info "User: $USER"

echo
echo "🎯 Health check complete!"
echo
echo "💡 If you found issues:"
echo "  - Run './scripts/update.sh' to update everything"
echo "  - Run specific commands mentioned in warnings"
echo "  - Check the documentation in CLAUDE.md"