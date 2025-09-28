# macOS Dotfiles

A comprehensive macOS development environment setup using Nix Darwin, Homebrew, and Stow for configuration management.

## Quick Setup

### Automated Installation (Recommended)

For a fresh macOS installation, run the automated setup script:

```bash
curl -fsSL https://github.com/GnrlSchnavy/dotfiles/raw/master/setup.sh | bash
```

Or clone first and run locally:

```bash
git clone https://github.com/GnrlSchnavy/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x setup.sh
./setup.sh
```

### What the setup script does:

1. **System Prerequisites**
   - Install Rosetta 2 (Apple Silicon only)
   - Install Xcode Command Line Tools
   - Clone dotfiles repository to `~/.dotfiles`

2. **Package Managers**
   - Install Homebrew
   - Install Nix package manager
   - Set up nix-darwin for macOS system management

3. **Configuration Management**
   - Apply custom nix-darwin configuration (modular system)
   - Set up dotfiles with Stow (category-based organization)
   - Configure shell environment with aliases and tools

4. **Verification**
   - Test all installations and configurations
   - Provide next steps and troubleshooting guidance

## Manual Setup

If you prefer manual control or need to troubleshoot:

### Prerequisites
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Nix
sh <(curl -L https://nixos.org/nix/install) --daemon
```

### Apply Configuration
```bash
# Clone repository
git clone https://github.com/GnrlSchnavy/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Apply nix-darwin configuration
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v

# Set up dotfiles
stow shell editors development system
```

## Architecture

This repository uses a **modular architecture** with three main components:

### 1. Nix Darwin (System Configuration)
Modular Nix configuration split across focused files:
- **`nix/flake.nix`**: Main system flake with host configuration
- **`nix/modules/packages.nix`**: CLI tools and development packages
- **`nix/modules/homebrew.nix`**: GUI apps, specialized tools, and Mac App Store apps
- **`nix/modules/system.nix`**: macOS system defaults and preferences
- **`nix/modules/dock.nix`**: Dock configuration and app layout
- **`nix/modules/environment.nix`**: Environment variables and system paths

### 2. Homebrew Integration
Strategic package management via nix-homebrew:
- **CLI tools**: Prefer Nix for reproducibility (git, rustc, nodejs)
- **GUI applications**: Use Homebrew casks (IntelliJ IDEA, VSCode, browsers)
- **Specialized tools**: Homebrew formulas for tools requiring taps (helm, kubectl)
- **Mac App Store**: Apps only available through App Store (Xcode, WireGuard)

### 3. Stow Dotfiles Management
Category-based dotfile organization:
- **`shell/`**: Shell configuration (.zprofile, .zshrc) and aliases
- **`git/`**: Git configuration (.gitconfig, .gitignore_global)
- **`editors/`**: Editor configurations (.ideavimrc)
- **`development/`**: Development tool configs (.docker/)
- **`system/`**: System-level settings (.claude/)

### Key Features
- ✅ **Modular Nix configuration** with clear separation of concerns
- ✅ **Strategic package management** with documented decision criteria
- ✅ **Category-based dotfiles** managed via GNU Stow
- ✅ **Automated setup script** for fresh macOS installations
- ✅ **Version-controlled Claude Code settings** for consistent AI tooling
- ✅ **Comprehensive documentation** with usage guidelines

## Usage

### Managing Configurations

```bash
# Rebuild system configuration
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v

# Update dotfiles
cd ~/.dotfiles
stow shell editors development system

# Add new packages to nix/modules/packages.nix or homebrew.nix
```

### Customization

- **Nix packages**: Edit `nix/modules/packages.nix`
- **Homebrew apps**: Edit `nix/modules/homebrew.nix`
- **System settings**: Edit `nix/modules/system.nix`
- **Shell config**: Edit `shell/.zprofile`

## Documentation

- **Complete guide**: See [CLAUDE.md](CLAUDE.md) for detailed documentation
- **Package strategy**: See [nix/PACKAGE-STRATEGY.md](nix/PACKAGE-STRATEGY.md) for package management guidelines
- **Claude integration**: See [system/.claude/README.md](system/.claude/README.md)
- **GitHub Actions**: Automated testing with GitHub Actions for macOS testing

## Troubleshooting

### Common Issues

1. **Xcode Command Line Tools**: If setup fails, install manually and re-run
2. **Homebrew PATH**: Restart terminal after installation
3. **Nix permissions**: Ensure you have admin privileges for initial setup
4. **Hostname mismatch**: Script works with any hostname but optimized for 'm4'

### Getting Help

- Check the setup script output for specific error messages
- Review the comprehensive documentation in CLAUDE.md
- Ensure you have a stable internet connection for downloads

## Requirements

- macOS (tested on Apple Silicon, compatible with Intel)
- Admin privileges for system configuration
- Internet connection for package downloads
- ~2-4 GB free space for all tools and applications

## Features

- ✅ **Zero-configuration setup** from blank macOS
- ✅ **Modular and maintainable** Nix configuration
- ✅ **Category-based dotfile organization** with Stow
- ✅ **Comprehensive development environment**
- ✅ **Version-controlled configurations**
- ✅ **Cross-machine consistency**
- ✅ **Automated testing** with GitHub Actions for macOS