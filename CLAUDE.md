# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this
repository. Detailed documentation lives in [`docs/`](docs/) — read the
relevant doc before making non-trivial changes.

## What this repo is

Personal dotfiles for macOS managed by **nix-darwin** (system) and
**home-manager** (user), wired together in one flake at
[`nix/flake.nix`](nix/flake.nix). All dotfiles — `.zshrc`,
`~/.config/git/*`, `.ideavimrc`, `~/.claude/*`, etc. — are symlinks
into the Nix store, recreated on every rebuild. No Stow.

Hosts: `m4` (personal, user `yvan`) and `m5` (work, user `yvan-sytac`)
— independent per-host configs, expected to diverge; `ci` mirrors m4
for the fresh-install CI test. See [docs/hosts.md](docs/hosts.md).

## The one command

```bash
# Applies system + user + homebrew config in one shot. sudo required.
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
```

Fresh machine bootstrap: `./setup.sh`
([docs/operations.md](docs/operations.md)). claude-mem needs a manual
per-machine install step — see [docs/claude-code.md](docs/claude-code.md#claude-mem-manual-per-machine-install).

## Hard rules (violations break the build or the machine)

1. **`git add` every new/changed file before rebuilding** — Nix flakes
   only read git-tracked files; untracked files cause
   "path does not exist" errors.
2. **`darwin-rebuild switch` needs `sudo`.**
3. **Never symlink files that apps rewrite at runtime**:
   `~/.claude/settings.json`, `~/.claude-mem/settings.json`,
   `~/.docker/config.json`. They use the reference-snapshot + seed
   pattern instead — see
   [docs/shell-and-dotfiles.md](docs/shell-and-dotfiles.md#files-that-must-not-be-symlinked).
4. **`homebrew.onActivation.cleanup = "zap"`** — any brew/cask not
   declared in the host's `homebrew.nix` is uninstalled on rebuild.
   Removing a line is how software gets uninstalled; manual
   `brew install`s don't survive.
5. **Per-host vs shared**: packages, homebrew, dock, git identity →
   `nix/hosts/<name>/`; everything shared → `nix/modules/` (system) or
   `nix/home/` (user). Don't put host-specific config in shared
   modules, and don't sync m4/m5 with each other unasked.
6. **Python is not centrally managed.** pyenv was deliberately removed
   (June 2026) — don't reintroduce pyenv into brews, zsh.nix, scripts,
   or docs.

## Where things live

| Change | File |
|---|---|
| CLI tool (nixpkgs) | `nix/hosts/<name>/packages.nix` |
| GUI app / brew formula | `nix/hosts/<name>/homebrew.nix` |
| Dock apps | `nix/hosts/<name>/dock.nix` |
| Git identity / ignores | `nix/hosts/<name>/git.nix` |
| macOS defaults | `nix/modules/system.nix` |
| Shell (zsh) init, env vars | `nix/home/zsh.nix` |
| New dotfile symlink | `nix/home/files.nix` |
| Claude Code settings/agents/skills | `system/.claude/` ([docs/claude-code.md](docs/claude-code.md)) |
| Neovim (NixVim) | `nix/nixvim/config/` — built per-host by `mkNvim` in `nix/flake.nix`; it is **not** a standalone flake |
| Flake inputs / host registration | `nix/flake.nix` |

Full architecture: [docs/architecture.md](docs/architecture.md).
Package source strategy (Nix vs Homebrew vs MAS):
[docs/packages.md](docs/packages.md).

## Verifying changes

```bash
# Fast eval check (no build) — catches typos, type errors, missing files
cd ~/.dotfiles/nix && nix flake check --no-build

# Full apply
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
```

CI runs a fresh-install test on every push ([docs/ci.md](docs/ci.md)).
If you change m4's brews, check the hardcoded formula list in
`.github/workflows/check.yml`'s smoke check.

## Development tools on these machines

- **Java**: jenv + temurin casks (`jenv global <ver>`); JAVA_HOME is
  set eagerly in zsh for `./mvnw` (see
  [docs/shell-and-dotfiles.md](docs/shell-and-dotfiles.md))
- **Node**: nvm (`nvm install <ver>`)
- **Kubernetes**: kubectl (+ helm/flux/kubeseal on m4); aliases `k`,
  `kgp`, `kaf`, … from `nix/modules/environment.nix`
- **Editors**: NixVim (Catppuccin, LSP, Telescope, Treesitter),
  IntelliJ + IdeaVim, VSCode
