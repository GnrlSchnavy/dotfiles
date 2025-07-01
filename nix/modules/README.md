# Nix Modules Documentation

This directory contains modular Nix Darwin configuration files organized by functionality.

## Module Overview

### `packages.nix`
**Nix packages for CLI tools and development utilities**

- **Core development tools**: git, rustc, nodejs, maven
- **Container ecosystem**: docker, docker-compose, minikube  
- **System utilities**: tree, jq, curl, ripgrep, fd
- **Language runtimes**: Java 23, Python 3

**Strategy**: Prefer Nix for CLI tools that benefit from reproducible builds and version consistency.

### `homebrew.nix`
**Homebrew packages for GUI apps and specialized tools**

- **GUI Applications (casks)**: IntelliJ IDEA, VSCode, browsers, Slack
- **CLI Tools (brews)**: kubectl, helm (with taps), version managers  
- **Mac App Store (masApps)**: WireGuard, Outlook, Xcode

**Strategy**: Use Homebrew for GUI applications, tools requiring taps, and macOS-specific software.

### `system.nix`
**macOS system configuration and defaults**

- Keyboard settings and key remapping
- Finder, dock, and interface preferences
- Security and screensaver settings
- Global system behaviors

### `dock.nix`
**Dock-specific configuration**

- Dock positioning and behavior
- Persistent applications
- Animation and timing settings

### `environment.nix`
**Environment variables and shell configuration**

- System-wide environment variables
- PATH modifications
- Shell integration settings

## Package Management Guidelines

### Adding New Packages

#### Nix Packages
```bash
# Edit packages.nix and add to appropriate category
vim ~/.dotfiles/nix/modules/packages.nix

# Apply changes
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v
```

#### Homebrew Packages
```bash
# Edit homebrew.nix
vim ~/.dotfiles/nix/modules/homebrew.nix

# Apply changes
darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v
```

### Decision Matrix

| Package Type | Use Nix | Use Homebrew | Use App Store |
|--------------|---------|--------------|---------------|
| CLI tools | ✅ Preferred | If not in Nix | Never |
| GUI apps | Never | ✅ Preferred | If exclusive |
| Development libraries | ✅ Always | Never | Never |
| System utilities | ✅ Preferred | If macOS-specific | Rarely |
| Version managers | Avoid | ✅ For shell integration | Never |
| Proprietary software | Never | ✅ Preferred | If required |

### Common Patterns

#### Language Ecosystems
- **Runtime**: Nix (nodejs, python3, rustc)
- **Version Manager**: Homebrew (nvm, pyenv, jenv)
- **Build Tools**: Nix (maven, gradle, cargo)

#### Container Tools
- **CLI**: Nix (docker, docker-compose, kubectl)
- **GUI**: Homebrew (docker desktop, lens)
- **Specialized**: Homebrew with taps (kubeseal, flux)

#### Development Environment
- **Editors (CLI)**: Nix (vim, emacs, nano)
- **IDEs (GUI)**: Homebrew (intellij-idea, vscode)
- **Utilities**: Mixed based on availability and features

## Troubleshooting

### Package Not Found
1. Check if package exists in nixpkgs: https://search.nixos.org/packages
2. Consider Homebrew alternative if not available
3. Check for different package name or version

### Version Conflicts
1. Nix packages are isolated and shouldn't conflict
2. Homebrew conflicts should use `brew upgrade` or `brew unlink`
3. Document exceptions in package comments

### Build Failures
1. Check Nix Darwin logs: `darwin-rebuild --show-trace`
2. Verify package exists for aarch64-darwin (Apple Silicon)
3. Consider fallback to Homebrew for problematic packages

## Best Practices

1. **Document rationale**: Add comments explaining non-obvious package choices
2. **Group by purpose**: Organize packages by functionality, not alphabetically
3. **Minimize duplication**: Same tool should only appear in one package manager
4. **Test thoroughly**: Always rebuild and verify after package changes
5. **Version consistency**: Use Nix for tools requiring specific versions
6. **Regular maintenance**: Periodically review and optimize package sources