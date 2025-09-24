# Claude Code Configuration Management

This directory contains Claude Code settings that are managed through the dotfiles system using Stow.

## Overview

Claude Code settings are version-controlled and symlinked to ensure consistent AI assistant configuration across different machines.

## Files

- **`settings.local.json`**: Active Claude Code permissions and tool access settings
- **`settings.template.json`**: Template file for setting up Claude on new machines
- **`README.md`**: This documentation file

## Usage

### Current Configuration
The active settings include permissions for common development tasks:
- File operations (ls, cat, chmod, rm)
- Git operations (add, commit, push)
- Package management (stow)
- System tools (nvim, find, grep)
- Nix operations (flake check)

### Setting Up on New Machines
1. Run the main setup script which handles Stow configuration
2. Or manually symlink: `cd ~/.dotfiles && stow system`
3. Settings will be symlinked to `~/.claude/settings.local.json`

### Modifying Settings
1. Edit `~/.dotfiles/system/.claude/settings.local.json`
2. Changes are automatically tracked in git
3. Re-run `stow system` if needed to ensure symlinks are correct

## Benefits

- **Consistency**: Same Claude permissions across all machines
- **Version Control**: Track changes to Claude configuration over time
- **Portability**: Easy to replicate Claude setup on new machines
- **Documentation**: Settings are documented and reviewable

## Integration with Dotfiles

This configuration is part of the system category in the Stow setup:
```bash
cd ~/.dotfiles
stow system  # This will symlink .claude/ to ~/.claude/
```

The settings become active immediately after symlinking.