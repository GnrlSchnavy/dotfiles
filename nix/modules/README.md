# Nix Modules

System-level (`nix-darwin`) modules **shared by every host** — imported by
[`flake.nix`](../flake.nix) into every `darwinConfiguration` via `sharedModules`.

Machine-specific modules a host can diverge on (`homebrew.nix`, `packages.nix`,
`dock.nix`) live **per-host** in [`../hosts/<name>/`](../hosts/), not here.
Shared user-level config lives in [`../home/`](../home/) under home-manager;
per-host `git.nix` lives in the host directory too.

## Shared modules (here)

### `system.nix`
macOS defaults: keyboard remap, screensaver, login window, finder
preferences, global UI/keyboard/sound settings.

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

## Per-host modules (in `../hosts/<name>/`)

These moved out of here so each machine installs its own set. A host pulls
them in via its descriptor's `systemModules` list (and `homeModules` for
`git.nix`). See [`../hosts/m4/`](../hosts/m4/) for the canonical example.

- **`packages.nix`** — Nix-managed CLI tools (`git`, `jq`, `ripgrep`, …).
  Language runtimes are deliberately *not* here — `jenv`/`nvm`/`pyenv` own
  those for per-project switching. See [`PACKAGE-STRATEGY.md`](../PACKAGE-STRATEGY.md).
- **`homebrew.nix`** — brews, casks, and Mac App Store apps via nix-homebrew.
- **`dock.nix`** — dock layout and persistent apps (built from a name list
  via a small `app` helper).
- **`git.nix`** (home-manager) — `programs.git` settings + global ignores;
  per-host so each machine can use a different identity.

## Adding a package

```bash
# CLI tool from nixpkgs — edit THIS machine's list
$EDITOR nix/hosts/$(scutil --get LocalHostName)/packages.nix

# GUI app or homebrew formula
$EDITOR nix/hosts/$(scutil --get LocalHostName)/homebrew.nix

# Apply
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
```

For when to use which package source, see [`PACKAGE-STRATEGY.md`](../PACKAGE-STRATEGY.md).