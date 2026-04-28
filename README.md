# macOS Dotfiles

A macOS development environment managed by **nix-darwin** (system) and
**home-manager** (user). One `darwin-rebuild switch` applies the entire
config; no Stow.

## Quick Setup (existing host)

If you're setting up a machine whose hostname already has a descriptor
in [nix/hosts/](nix/hosts/) (e.g. `m4`), one command:

```bash
git clone https://github.com/GnrlSchnavy/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./setup.sh
```

The script verifies a host descriptor exists for the current hostname,
installs Homebrew + Nix, and applies the flake.

## Setting up a new host

`scutil --get LocalHostName` must match a descriptor at
`nix/hosts/<hostname>/default.nix`. To onboard a new Mac:

1. **Copy the template:**
   ```bash
   cp -r nix/hosts/template "nix/hosts/$(scutil --get LocalHostName)"
   ```
2. **Edit the new descriptor** — replace the `REPLACE_ME_*` placeholders
   with your username and hostname.
3. **Register it in [nix/flake.nix](nix/flake.nix)** under the `hosts`
   attrset:
   ```nix
   hosts = {
     m4 = import ./hosts/m4;
     <your-hostname> = import ./hosts/<your-hostname>;
   };
   ```
4. **Stage the new files** so the flake can see them:
   ```bash
   git add nix/hosts/<your-hostname>/ nix/flake.nix
   ```
5. **Commit and push** (so future machines can clone the descriptor too).
6. Run `./setup.sh` on the new machine.

## Post-install steps

The setup script installs version managers (`jenv`, `nvm`, `pyenv`) but
doesn't install language toolchains through them. Bootstrap them per
machine:

```bash
# Java (after installing a JDK, e.g. via brew install temurin@25)
jenv add /Library/Java/JavaVirtualMachines/temurin-25.jdk/Contents/Home
jenv global temurin-25

# Node
nvm install --lts

# Python
pyenv install 3.13
pyenv global 3.13

# (Optional) Bun, used by the claude-mem alias
curl -fsSL https://bun.sh/install | bash
```

## Manual rebuild

After setup, future config changes are applied with:

```bash
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
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

### 3. home-manager (User Configuration)
User-level dotfiles, all symlinked from the Nix store:
- **`nix/home/zsh.nix`**: Shell config (.zshrc, .zprofile, .zshenv)
- **`nix/home/git.nix`**: Git config (~/.config/git/config, ~/.config/git/ignore)
- **`nix/home/files.nix`**: File-pointer dotfiles (.ideavimrc, .docker/, .claude/)

The dotfile contents still live where they always did (`editors/`,
`development/`, `system/`) — home-manager just creates the symlinks.

### Key Features
- ✅ **Modular Nix configuration** with clear separation of concerns
- ✅ **Strategic package management** with documented decision criteria
- ✅ **Declarative user dotfiles** via home-manager
- ✅ **Automated setup script** for fresh macOS installations
- ✅ **Version-controlled Claude Code settings** for consistent AI tooling
- ✅ **Comprehensive documentation** with usage guidelines

## Usage

### Managing Configurations

```bash
# Rebuild — applies both system (nix-darwin) and user (home-manager) config
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v

# Add new packages to nix/modules/packages.nix or nix/modules/homebrew.nix
# Edit user dotfiles in nix/home/*.nix or the source files in editors/, system/, etc.
# Then: darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v
```

### Customization

- **Nix packages**: Edit `nix/modules/packages.nix`
- **Homebrew apps**: Edit `nix/modules/homebrew.nix`
- **System settings**: Edit `nix/modules/system.nix`
- **Shell config**: Edit `nix/home/zsh.nix`
- **Git config**: Edit `nix/home/git.nix`

## Documentation

- **Complete guide**: See [CLAUDE.md](CLAUDE.md) for detailed documentation
- **Package strategy**: See [nix/PACKAGE-STRATEGY.md](nix/PACKAGE-STRATEGY.md) for package management guidelines
- **Claude integration**: See [system/.claude/README.md](system/.claude/README.md)

## Troubleshooting

### Common Issues

1. **Xcode Command Line Tools**: If setup fails, install manually and re-run
2. **Homebrew PATH**: Restart terminal after installation
3. **Nix permissions**: Ensure you have admin privileges for initial setup
4. **No host descriptor for hostname**: Setup will tell you exactly what to do
   — copy `nix/hosts/template/` to `nix/hosts/<hostname>/`, edit the
   `REPLACE_ME_*` placeholders, register in `nix/flake.nix`

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

- ✅ **One-command setup** from blank macOS
- ✅ **Multi-host support** — copy a template, register, run setup
- ✅ **Modular Nix configuration** with clear separation of concerns
- ✅ **Declarative user dotfiles** via home-manager (no Stow)
- ✅ **Version-controlled configurations**
- ✅ **Cross-machine consistency**