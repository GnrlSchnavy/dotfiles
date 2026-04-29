#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_section() { echo -e "${BLUE}🔍 $1${NC}"; }
print_success() { echo -e "  ${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
print_error()   { echo -e "  ${RED}❌ $1${NC}"; }
print_info()    { echo -e "  ℹ️  $1"; }

echo "🔍 Dotfiles Health Check"
echo

# --- Repository ---
print_section "Repository"
if [ -d "$HOME/.dotfiles" ]; then
    cd "$HOME/.dotfiles" || exit 1
    print_success "~/.dotfiles found"

    if git rev-parse --git-dir > /dev/null 2>&1; then
        print_success "git repo valid"
        if git diff --quiet && git diff --cached --quiet; then
            print_success "working tree clean"
        else
            print_warning "uncommitted changes (run 'git status')"
        fi
        print_info "branch: $(git branch --show-current)"
    else
        print_error "not a git repo"
    fi
else
    print_error "~/.dotfiles not found"
    exit 1
fi

# --- Nix / nix-darwin ---
print_section "Nix"
if command -v nix > /dev/null 2>&1; then
    print_success "nix installed ($(nix --version | awk '{print $NF}'))"
    if command -v darwin-rebuild > /dev/null 2>&1; then
        print_success "darwin-rebuild on PATH"
        if (cd nix && nix flake check --no-build > /dev/null 2>&1); then
            print_success "flake evaluates cleanly"
        else
            print_error "flake has eval errors (run 'cd nix && nix flake check')"
        fi
    else
        print_error "darwin-rebuild not on PATH"
    fi
else
    print_error "nix not installed"
fi

# --- Host descriptor ---
print_section "Host descriptor"
HOSTNAME=$(scutil --get LocalHostName)
if [ -f "nix/hosts/$HOSTNAME/default.nix" ]; then
    print_success "nix/hosts/$HOSTNAME/default.nix exists"
else
    print_error "no host descriptor for $HOSTNAME"
    print_info "create one from nix/hosts/template/, register in nix/flake.nix"
fi

# --- Homebrew ---
print_section "Homebrew"
if command -v brew > /dev/null 2>&1; then
    print_success "brew on PATH"
    if brew doctor > /dev/null 2>&1; then
        print_success "brew doctor clean"
    else
        print_warning "brew doctor has warnings (run 'brew doctor')"
    fi
else
    print_error "brew not installed"
fi

# --- Home-manager symlinks ---
print_section "Home-manager symlinks"
managed_files=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.zshenv"
    "$HOME/.config/git/config"
    "$HOME/.config/git/ignore"
    "$HOME/.ideavimrc"
    "$HOME/.docker/config.json"
    "$HOME/.claude/settings.local.json"
)
for f in "${managed_files[@]}"; do
    if [ -L "$f" ] && [ -e "$f" ]; then
        print_success "${f/#$HOME/~}"
    elif [ -L "$f" ]; then
        print_error "${f/#$HOME/~} (broken symlink)"
    elif [ -e "$f" ]; then
        print_warning "${f/#$HOME/~} exists but isn't a symlink"
    else
        print_warning "${f/#$HOME/~} missing"
    fi
done

# --- Tooling ---
print_section "Tooling"
for tool in git brew kubectl docker nvim code; do
    if command -v "$tool" > /dev/null 2>&1; then
        print_success "$tool"
    else
        print_warning "$tool not on PATH"
    fi
done

# --- Version managers ---
print_section "Version managers"
[ -d "$HOME/.jenv" ]   && print_success "jenv installed"   || print_warning "jenv (~/.jenv missing)"
[ -d "$HOME/.nvm" ]    && print_success "nvm installed"    || print_warning "nvm (~/.nvm missing)"
[ -d "$HOME/.pyenv" ]  && print_success "pyenv installed"  || print_warning "pyenv (~/.pyenv missing)"

# --- System info ---
print_section "System"
print_info "macOS:        $(sw_vers -productVersion)"
print_info "architecture: $(uname -m)"
print_info "hostname:     $HOSTNAME"
print_info "user:         $USER"
print_info "shell:        $SHELL"

echo
echo "💡 Found issues? Try './scripts/update.sh' or rebuild manually:"
echo "    sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$HOSTNAME -v"
