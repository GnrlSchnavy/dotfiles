# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository for macOS using Nix Darwin, Homebrew, and GNU Stow for configuration management. The setup includes a comprehensive system configuration with development tools, applications, and custom settings.

## Setup and Installation

### Initial Setup
Run the setup script to bootstrap the entire system:
```bash
./setup.sh
```

This script will:
1. Install Rosetta and Xcode command line tools
2. Clone dotfiles to `~/.dotfiles`
3. Install Nix package manager
4. Install and configure nix-darwin
5. Apply the custom Nix configuration
6. Use Stow to symlink dotfiles

### System Rebuild
To apply changes to the Nix Darwin configuration:
```bash
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v
```

### Dotfile Management
This repository uses GNU Stow for symlinking dotfiles organized by category. After making changes to dotfiles:
```bash
cd ~/.dotfiles
# Stow specific categories
stow shell        # Shell configurations (.zprofile, .zshrc)
stow git          # Git configurations (.gitconfig, .gitignore_global)
stow editors      # Editor configurations (.ideavimrc)
stow development  # Development tools (.docker)
stow system       # System configurations (.claude)

# Or stow all categories at once
stow shell git editors development system
```

## Architecture

### Nix Configuration Structure
- **Main flake**: `nix/flake.nix` - Core system configuration for the "m4" host
- **NixVim**: `nix/nixvim/` - Separate flake for Neovim configuration
- **Host**: Configuration is specifically for "m4" (Apple Silicon Mac)

### Key Components

#### System Management
- **nix-darwin**: Primary system configuration management
- **Homebrew**: GUI applications and some CLI tools via nix-homebrew integration
- **Stow**: Dotfile symlinking

#### Package Sources
- **Nix packages**: Core development tools (Git, Maven, Docker, Rust, Java 23)
- **Homebrew casks**: GUI applications (IntelliJ, VSCode, browsers, etc.)
- **Homebrew formulas**: CLI tools (tmux, helm, kubectl tools)
- **Mac App Store**: Apps via `masApps` configuration

#### Configuration Files Organization
**Shell Configuration** (`shell/`)
- `.zprofile`: Shell environment setup with Homebrew, NVM, kubectl aliases
- `.zshrc`: Zsh shell configuration with jenv and kubectl completion

**Git Configuration** (`git/`)
- `.gitconfig`: Personal git configuration (user, core settings)
- `.gitignore_global`: Global gitignore patterns
- `.config/git/ignore`: Git-specific ignore patterns for Claude settings

**Editor Configuration** (`editors/`)
- `.ideavimrc`: IntelliJ IDEA Vim plugin configuration
- `nix/nixvim/config/`: Neovim configuration with Catppuccin theme, LSP, Telescope

**Development Configuration** (`development/`)
- `.docker/`: Docker configuration and settings

**System Configuration** (`system/`)
- `.claude/settings.local.json`: Claude Code permissions and tool access
- `.claude/README.md`: Documentation for Claude configuration management
- `.claude/settings.template.json`: Template for environment-specific settings

### System Customizations
- **macOS defaults**: Dock on right, dark mode, optimized animations
- **Keyboard**: Caps Lock remapped to Escape
- **Security**: Screen saver password prompt after 5 minutes
- **Dock**: Static apps including Brave, Spotify, Slack, Obsidian, IntelliJ IDEA

## Development Tools

### Available Tools
- **Java**: Zulu JDK 23 with jenv for version management
- **Rust**: rustc compiler
- **Node.js**: via nvm
- **Python**: via pyenv
- **Docker**: Both Nix package and Homebrew cask
- **Kubernetes**: kubectl, helm, kubeseal, flux, kdoctor

### Editor Configuration
- **Neovim**: Configured via NixVim with LSP, Treesitter, Telescope
- **IntelliJ IDEA**: With IdeaVim plugin configured
- **VSCode**: Available via Homebrew

## Claude Code Integration

### Configuration Management
Claude Code settings are version-controlled and managed through Stow:
- **Location**: `system/.claude/settings.local.json`
- **Symlinked to**: `~/.claude/settings.local.json`
- **Purpose**: Consistent Claude Code experience across machines

### Claude Settings
The current configuration includes:
- **Permissions**: Allowed bash commands for system operations
- **Tool Access**: Controlled access to system commands
- **Version Control**: Settings changes are tracked in git

### Working with Claude Settings
```bash
# View current Claude permissions
cat ~/.claude/settings.local.json

# Edit Claude settings (changes will be tracked in git)
$EDITOR ~/.dotfiles/system/.claude/settings.local.json

# Use template for new environments
cp ~/.dotfiles/system/.claude/settings.template.json ~/.dotfiles/system/.claude/settings.local.json

# Re-stow after making changes
cd ~/.dotfiles && stow system

# View Claude configuration documentation
cat ~/.dotfiles/system/.claude/README.md
```

### Benefits
- **Consistency**: Same Claude permissions across different machines
- **Version Control**: Track changes to Claude configuration over time
- **Portability**: Easy to replicate Claude setup on new machines
- **Collaboration**: Share Claude configurations with team members

## Common Commands

### Nix Operations
```bash
# Rebuild system configuration
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v

# Update flake lock files
nix flake update ~/.dotfiles/nix

# Check NixVim configuration
nix flake check ~/.dotfiles/nix/nixvim
```

### Development Environment
```bash
# Kubernetes shortcuts (defined in .zprofile)
k get pods    # kubectl get pods
kgp          # kubectl get pods
kaf file.yml # kubectl apply -f file.yml

# Jump to directories
j <partial-name>  # autojump navigation
```

### Package Management

This repository uses a strategic approach to package management across Nix and Homebrew:

#### Package Sources Strategy
- **Nix packages** (`nix/modules/packages.nix`): CLI tools, development libraries, system utilities
- **Homebrew casks** (`nix/modules/homebrew.nix`): GUI applications, proprietary software  
- **Homebrew brews** (`nix/modules/homebrew.nix`): Tools requiring taps, version managers
- **Mac App Store** (`nix/modules/homebrew.nix`): Apps exclusive to App Store

#### Decision Matrix
| Tool Type | Nix | Homebrew | App Store |
|-----------|-----|----------|-----------|
| CLI development tools | ✅ Preferred | If not available | Never |
| GUI applications | Never | ✅ Preferred | If exclusive |
| Version managers | Avoid | ✅ Shell integration | Never |
| System utilities | ✅ Preferred | If macOS-specific | Rarely |

#### Adding Packages
```bash
# Nix packages (CLI tools, development)
vim ~/.dotfiles/nix/modules/packages.nix

# Homebrew (GUI apps, specialized tools)  
vim ~/.dotfiles/nix/modules/homebrew.nix

# Apply changes
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v
```

#### Examples by Category
- **Development**: git, rustc, nodejs (Nix) + IntelliJ IDEA, VSCode (Homebrew)
- **Containers**: docker CLI (Nix) + Docker Desktop (Homebrew)  
- **Languages**: python3 (Nix) + pyenv (Homebrew for version management)
- **Kubernetes**: kubectl (Nix) + helm, flux (Homebrew for taps)

See `nix/PACKAGE-STRATEGY.md` and `nix/modules/README.md` for complete guidelines.

## Notes

- The configuration is optimized for Apple Silicon (aarch64-darwin)
- Homebrew auto-updates and upgrades on activation
- System uses experimental Nix features (flakes, nix-command)
- NixVim is included as a local flake input for custom Neovim builds