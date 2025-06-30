# macOS Dotfiles

A comprehensive macOS development environment setup using Nix Darwin, Homebrew, and Stow for configuration management.

## Quick Setup

### Automated Installation (Recommended)

For a fresh macOS installation, run the automated setup script:

```bash
curl -fsSL https://gitlab.com/YvanStemmerik/dotfiles/-/raw/master/setup.sh | bash
```

Or clone first and run locally:

```bash
git clone https://gitlab.com/YvanStemmerik/dotfiles.git ~/.dotfiles
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
git clone https://gitlab.com/YvanStemmerik/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Apply nix-darwin configuration
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v

# Set up dotfiles
stow shell editors development system
```

## What's Included

### Development Tools
- **Nix packages**: Git, Maven, Docker, Rust, Java 23, and more
- **Homebrew apps**: IntelliJ IDEA, VSCode, browsers, productivity tools
- **Shell setup**: zsh with kubectl aliases, autojump, and environment configuration

### System Configuration
- **macOS defaults**: Optimized settings for development workflow
- **Dock configuration**: Right-side dock with essential applications
- **Keyboard**: Caps Lock remapped to Escape
- **Security**: Screen saver password protection

### Dotfiles Organization
- **shell/**: Shell configuration and aliases (.zprofile)
- **editors/**: Editor configurations (.ideavimrc)
- **development/**: Development tool configs (.docker/)
- **system/**: System-level settings (.claude/)

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
- **Improvement roadmap**: See [improvement-plan.md](improvement-plan.md)
- **Claude integration**: See [system/.claude/README.md](system/.claude/README.md)

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