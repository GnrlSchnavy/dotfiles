# Nix Modules

System-level (`nix-darwin`) modules. Each one is imported by
[`flake.nix`](../flake.nix) into every host's `darwinConfiguration`.

User-level config lives next door in [`../home/`](../home/) under
home-manager.

## Modules

### `packages.nix`
Nix-managed CLI tools. Currently:
- `git`, `maven` — core development
- `tree`, `jq`, `curl`, `wget`, `ripgrep`, `fd`, `bat` — system utilities
- `unzip`, `p7zip` — archives
- `mkalias`, `htop`, `fastfetch` — misc
- `wireguard-tools` — networking

Language runtimes (Java, Node, Python) are deliberately *not* here —
they're managed by `jenv`/`nvm`/`pyenv` for per-project version
switching. See [`PACKAGE-STRATEGY.md`](../PACKAGE-STRATEGY.md).

### `homebrew.nix`
Brews, casks, and Mac App Store apps via nix-homebrew.
- **Brews**: kubernetes ecosystem (`helm`, `kubectl`, `kubeseal`,
  `kdoctor`, `flux`), version managers (`jenv`, `nvm`, `pyenv`, `pipx`),
  shell tooling (`tmux`, `autojump`, `gh`)
- **Casks**: ~36 GUI apps (browsers, IDEs, comms, productivity, etc.)
- **masApps**: currently empty

### `system.nix`
macOS defaults: keyboard remap, screensaver, login window, finder
preferences, global UI/keyboard/sound settings.

### `dock.nix`
Dock layout: position, autohide, persistent apps. Apps are built
from a name list via a small `app` helper to avoid duplicating
the `/Applications/${name}.app` path.

### `environment.nix`
System-wide env vars (`EDITOR`, `VISUAL`) and shell aliases
(kubectl shortcuts).

### `nix.nix`
Nix-the-package-manager configuration:
- `nixpkgs.config.allowUnfree = true`
- `nix.settings`: experimental features, trusted users (`@admin`),
  `warn-dirty = false`
- `nix.gc.automatic`: weekly garbage collection of >30d generations
- `nix.optimise.automatic`: launchd-scheduled store dedup

## Adding a package

```bash
# CLI tool from nixpkgs
$EDITOR nix/modules/packages.nix

# GUI app or homebrew formula
$EDITOR nix/modules/homebrew.nix

# Apply
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
```

For when to use which package source, see [`PACKAGE-STRATEGY.md`](../PACKAGE-STRATEGY.md).
