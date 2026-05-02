# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for macOS managed by **nix-darwin** (system) and
**home-manager** (user). All dotfiles — `.zshrc`, `.zprofile`,
`.gitconfig`, `.ideavimrc`, `.claude/*`, etc. — are symlinks into the
Nix store, recreated on every `darwin-rebuild switch`. No Stow.

## Setup and Installation

### Initial Setup
Run the setup script to bootstrap the entire system:
```bash
./setup.sh
```

This script will:
1. Install Rosetta and Xcode command line tools
2. Clone dotfiles to `~/.dotfiles`
3. Install Homebrew (used as nix-homebrew's package source)
4. Install Nix package manager
5. Install and configure nix-darwin
6. Apply the custom Nix configuration (which also activates home-manager)

### System Rebuild
A single command applies both system-level and user-level config:
```bash
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v
```

This rebuilds nix-darwin (system packages, defaults, dock, homebrew
bundle) AND activates home-manager (user dotfiles, shell, git, etc.).

## Architecture

### Nix Configuration Structure
- **Main flake**: `nix/flake.nix` - input plumbing + per-host wiring
- **Host descriptors**: `nix/hosts/<name>/default.nix` - hostname, username, arch, stateVersion
- **System modules**: `nix/modules/*.nix` - shared nix-darwin config
- **User modules**: `nix/home/*.nix` - home-manager config (shell, git, dotfiles)
- **NixVim**: `nix/nixvim/` - separate flake for Neovim configuration
- **Currently configured host**: `m4` (Apple Silicon Mac)

### Key Components

#### System Management
- **nix-darwin**: System-level config (packages, macOS defaults, dock, launchd, etc.)
- **home-manager**: User-level config (shell, git, dotfiles symlinked from Nix store)
- **Homebrew**: GUI applications via nix-homebrew integration (declared in `nix/modules/homebrew.nix`)

#### Package Sources
- **Nix packages** (`nix/modules/packages.nix`): CLI tools, build tools (git, maven, jq, etc.)
- **Homebrew casks** (`nix/modules/homebrew.nix`): GUI applications (IntelliJ, VSCode, browsers, etc.)
- **Homebrew formulas** (`nix/modules/homebrew.nix`): CLI tools needing taps or shell integration (helm, jenv, nvm, pyenv)
- **Mac App Store** (`nix/modules/homebrew.nix` `masApps`): App-Store-only apps

#### Configuration Files Organization

**Shell** — managed by home-manager (`nix/home/zsh.nix`)
- Login-shell init in `programs.zsh.profileExtra` (Homebrew init, autojump, NVM)
- Interactive-shell init in `programs.zsh.initContent` (jenv/pyenv lazy-load, kubectl completion, bun, JAVA_HOME)
- Aliases in `programs.zsh.shellAliases`
- Static env vars in `home.sessionVariables`

**Git** — managed by home-manager (`nix/home/git.nix`)
- All settings in `programs.git.settings` (writes ~/.config/git/config)
- Global ignore patterns in `programs.git.ignores` (writes ~/.config/git/ignore)

**Editor / Claude** — file-pointer dotfiles (`nix/home/files.nix`)
- `editors/.ideavimrc` → `~/.ideavimrc`
- `system/.claude/{settings.local.json,settings.template.json,README.md}` → `~/.claude/...`

Note: `~/.docker/config.json` is *not* home-manager-managed. Docker
Desktop rewrites that file at runtime (current context, credential
store), which fails when it's a Nix-store symlink (cross-filesystem
rename). `development/.docker/config.json` stays in the repo as a
reference of the defaults we used to pin.

**Neovim** — built per-host in `flake.nix` from `nix/nixvim/config/`
- Catppuccin theme, LSP for many languages, Telescope, Treesitter

### System Customizations
- **macOS defaults**: Dock on right, dark mode, optimized animations
- **Keyboard**: Caps Lock remapped to Escape
- **Security**: Screen saver password prompt after 5 minutes
- **Dock**: Static apps including Brave, Spotify, Slack, Obsidian, IntelliJ IDEA

## Development Tools

### Available Tools
- **Java**: managed by jenv (set version with `jenv global <ver>`)
- **Node.js**: managed by nvm (set version with `nvm install <ver>`)
- **Python**: managed by pyenv (set version with `pyenv global <ver>`)
- **Docker**: Docker Desktop via Homebrew cask
- **Kubernetes**: kubectl, helm, kubeseal, flux, kdoctor

### Editor Configuration
- **Neovim**: Configured via NixVim with LSP, Treesitter, Telescope
- **IntelliJ IDEA**: With IdeaVim plugin configured
- **VSCode**: Available via Homebrew

## Claude Code Integration

### Configuration Management
Claude Code settings are version-controlled and managed by home-manager:
- **Source**: `system/.claude/settings.local.json` (in this repo)
- **Symlinked to**: `~/.claude/settings.local.json` (via `nix/home/files.nix`)
- **Purpose**: Consistent Claude Code experience across machines

### Working with Claude Settings
```bash
# View current Claude permissions
cat ~/.claude/settings.local.json

# Edit Claude settings (changes will be tracked in git)
$EDITOR ~/.dotfiles/system/.claude/settings.local.json

# Apply: rebuild reads the new content and home-manager updates the symlink
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v

# Use template for new environments
cp ~/.dotfiles/system/.claude/settings.template.json ~/.dotfiles/system/.claude/settings.local.json
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
# Kubernetes shortcuts (defined in nix/modules/environment.nix)
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