# Maintenance Scripts

This directory contains automation scripts for maintaining your dotfiles setup.

## Scripts Overview

### `update.sh`
**Purpose**: Update all system components in the correct order
**Usage**: `./scripts/update.sh`

What it does:
- Updates the dotfiles Git repository
- Updates Nix flake inputs
- Applies the latest system configuration via darwin-rebuild
- Re-stows dotfiles to ensure correct symlinks
- Performs basic health checks

### `backup.sh`
**Purpose**: Create a comprehensive backup of current configurations
**Usage**: `./scripts/backup.sh`

What it does:
- Creates timestamped backup directory
- Backs up all stow-managed dotfiles
- Saves system state information (Darwin version, Homebrew packages, macOS version)
- Generates restore script and documentation
- Provides guidance for restoration

### `check.sh`
**Purpose**: Comprehensive health check of your dotfiles setup
**Usage**: `./scripts/check.sh`

What it does:
- Verifies repository status and Git state
- Validates Nix configuration and flake
- Checks Homebrew installation and health
- Verifies Stow configuration and symlinks
- Tests essential tool availability
- Reports environment and system information

## Usage Patterns

### Regular Maintenance
```bash
# Weekly update routine
./scripts/update.sh

# Monthly health check
./scripts/check.sh
```

### Before Major Changes
```bash
# Create backup before experimenting
./scripts/backup.sh

# Make your changes...

# Verify everything still works
./scripts/check.sh
```

### Troubleshooting
```bash
# Diagnose issues
./scripts/check.sh

# Try to fix with update
./scripts/update.sh

# If problems persist, restore from backup
# (use the restore script in your backup directory)
```

## Script Features

### Error Handling
- All scripts use `set -e` for fail-fast behavior
- Colored output for easy issue identification
- Comprehensive error messages with next steps

### Dry-run Capabilities
- Stow operations include dry-run checks
- Non-destructive verification before changes

### Comprehensive Logging
- Clear progress indication
- Summary of actions taken
- Guidance for next steps

## Customization

You can modify these scripts to:
- Add additional backup locations
- Include more health checks
- Customize update procedures
- Add notification systems

Just ensure you maintain the fail-safe behavior and clear output formatting.

## Integration with Dotfiles

These scripts are designed to work with your specific setup:
- Nix Darwin configuration in `nix/`
- Stow categories: shell, git, editors, development, system
- Homebrew managed via nix-homebrew

If you change your dotfiles structure, update the scripts accordingly.