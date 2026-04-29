# Package Management Strategy

This document defines the strategy for choosing between Nix packages, Homebrew formulas, Homebrew casks, and Mac App Store apps.

## Decision Matrix

### Nix Packages (`nix/modules/packages.nix`)
**Use for: CLI tools, development libraries, system utilities that benefit from reproducibility**

**Criteria:**
- ✅ Command-line tools and utilities
- ✅ Development libraries and compilers
- ✅ Tools that need specific versions or reproducible builds
- ✅ Cross-platform tools available in nixpkgs
- ✅ Tools used in development workflows

**Examples:**
- Development: `git`, `maven`
- System utilities: `tree`, `jq`, `curl`, `wget`, `ripgrep`, `fd`, `bat`
- Networking CLIs: `wireguard-tools`

Note: Language runtimes (Java, Node, Python) are deliberately *not*
managed by Nix. They live behind version managers (`jenv`, `nvm`,
`pyenv`) so each project can pin its own version. See
[`homebrew.nix`](modules/homebrew.nix) and [`home/zsh.nix`](home/zsh.nix).

### Homebrew Formulas (`homebrew.brews`)
**Use for: CLI tools not available in Nix or requiring Homebrew-specific features**

**Criteria:**
- ✅ Tools not available in nixpkgs or with poor Nix support
- ✅ Tools requiring Homebrew taps (e.g., `fluxcd/tap/flux`)
- ✅ macOS-specific CLI tools with Homebrew integration
- ✅ Tools needing frequent updates outside Nix release cycle

**Examples:**
- Kubernetes: `helm`, `kubectl`, `kubeseal`, `kdoctor`, `fluxcd/tap/flux`
- Version managers: `jenv`, `nvm`, `pyenv`, `pipx`
- Shell tooling: `tmux`, `autojump`, `gh`

### Homebrew Casks (`homebrew.casks`)
**Use for: GUI applications, proprietary software, macOS apps**

**Criteria:**
- ✅ GUI applications with native macOS interfaces
- ✅ Proprietary software not available in Nix
- ✅ Applications requiring macOS-specific features
- ✅ Software with frequent updates or beta channels

**Examples:**
- Browsers: `google-chrome`, `brave-browser`, `firefox`
- Development: `visual-studio-code`, `intellij-idea`, `docker`
- Productivity: `slack`, `discord`, `notion`, `obsidian`
- System tools: `alfred`, `rectangle`, `1password`

### Mac App Store (`homebrew.masApps`)
**Use for: Apps only available through App Store or requiring App Store features**

**Criteria:**
- ✅ Apps only distributed through Mac App Store
- ✅ Apps requiring App Store DRM or sandboxing
- ✅ Apps needing automatic updates through macOS
- ✅ Apps with paid licenses tied to Apple ID

**Examples:**
- System tools: `WireGuard`, `TestFlight`
- Productivity: `Pages`, `Numbers`, `Keynote`
- Development: `Xcode` (when needed)

## Package Organization

### By Category

#### Core Development Tools (Nix)
- Version control: `git`
- Build tools: `maven`

#### System Utilities (Nix)
- File operations: `tree`, `fd`, `ripgrep`
- JSON/Data: `jq`
- Network: `curl`, `wget`, `wireguard-tools`
- Archive: `unzip`, `p7zip`

#### GUI Applications (Homebrew Casks)
- Editors: `visual-studio-code`, `intellij-idea`
- Browsers: `google-chrome`, `brave-browser`, `firefox`
- Communication: `slack`, `discord`
- Productivity: `alfred`, `rectangle`, `obsidian`

#### Specialized CLI Tools (Homebrew Brews)
- Kubernetes: `helm`, `kubectl`, `kubeseal`, `kdoctor`
- Language managers: `jenv`, `nvm`, `pyenv` (for shell-integrated version switching)

## Conflict Resolution

### When a package is available in multiple sources:

1. **Prefer Nix** for reproducibility if:
   - It's a core development tool
   - You need a specific version
   - It's used in scripts or automation

2. **Use Homebrew** if:
   - Nix version is outdated or broken
   - Need shell integration (pyenv, nvm)
   - Requires frequent updates

3. **Document exceptions** in comments explaining why

## Migration Guidelines

### Moving packages between sources:

1. **Document the reason** in commit message
2. **Test thoroughly** after migration
3. **Update documentation** if workflow changes
4. **Consider dependencies** that might break

### Example migrations:
- `kubectl` Homebrew → Nix (version consistency)
- GUI `docker` Cask → keep (GUI application)
- CLI `docker` Nix → keep (development tool)

## Best Practices

1. **Minimize duplication** - same tool should only be in one source
2. **Document rationale** - add comments explaining non-obvious choices
3. **Group by purpose** - organize packages by use case, not source
4. **Regular review** - periodically audit package sources for optimization
5. **Version pinning** - use Nix for tools needing reproducible versions