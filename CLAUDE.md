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

Hosts: `m5` (user `yvan-sytac`) is the only real machine — it serves
as both the personal and work Mac; `ci` mirrors m5 for the
fresh-install CI test. `m4` was sold and removed in August 2026. See
[docs/hosts.md](docs/hosts.md).

## The one command

```bash
# Applies system + user + homebrew config in one shot. sudo required.
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
```

Fresh machine bootstrap: `./setup.sh`
([docs/operations.md](docs/operations.md)). After the first rebuild,
once per machine: `mise install` (the Java/Node versions) and
`cc-lanes-setup` (the codemem plugin, in both Claude Code lanes).

## Hard rules (violations break the build or the machine)

1. **`git add` every new/changed file before rebuilding** — Nix flakes
   only read git-tracked files; untracked files cause
   "path does not exist" errors.
2. **`darwin-rebuild switch` needs `sudo`.**
3. **Never symlink files that apps rewrite at runtime**:
   `~/.claude/settings.json`, `~/.claude-work/settings.json`,
   `~/.docker/config.json`. The Claude Code lanes use a reference
   snapshot plus an activation-time merge of owned keys instead — see
   [docs/shell-and-dotfiles.md](docs/shell-and-dotfiles.md#files-that-must-not-be-symlinked).
4. **`homebrew.onActivation.cleanup = "zap"`** — any brew/cask not
   declared in the host's `homebrew.nix` is uninstalled on rebuild.
   Removing a line is how software gets uninstalled; manual
   `brew install`s don't survive.
5. **Per-host vs shared**: packages, homebrew, dock, git identity →
   `nix/hosts/<name>/`; everything shared → `nix/modules/` (system) or
   `nix/home/` (user). Don't put host-specific config in shared
   modules — the split is what keeps onboarding the next Mac a copy
   rather than a refactor, even though m5 is currently the only host.
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
| Java/Node versions (mise) | `nix/home/mise.nix` |
| New dotfile symlink | `nix/home/files.nix` |
| Secrets (Proton Pass refs, `pass-get`/`pass-render`) | `nix/home/secrets.nix` ([docs/secrets.md](docs/secrets.md)) |
| Claude Code lanes (`cc-personal`/`cc-work`), guards, settings merge, model aliases | `nix/home/claude-lanes.nix` ([docs/claude-code.md](docs/claude-code.md#two-claude-code-lanes)) |
| codemem memory (per-lane observer configs) | `nix/home/codemem.nix` ([docs/claude-code.md](docs/claude-code.md#codemem-memory)) |
| Claude Code settings/agents/commands/skills, global `CLAUDE.md` | `system/.claude/` ([docs/claude-code.md](docs/claude-code.md)) |
| Work-lane hooks + Ahold `CLAUDE.md` overlay | `system/.claude-work/` ([docs/claude-code.md](docs/claude-code.md#instructions--agents-per-lane)) |
| Agent workflow (`/flow`, roles, per-lane tiers) | `system/.claude/agents/` + `commands/flow*.md` ([docs/agent-workflow.md](docs/agent-workflow.md)) |
| Per-client agents/rules | private per-client repo + `cc-tooling` ([docs/client-tooling.md](docs/client-tooling.md)) |
| Neovim (NixVim) | `nix/nixvim/config/` — built per-host by `mkNvim` in `nix/flake.nix`; it is **not** a standalone flake |
| Flake inputs / host registration | `nix/flake.nix` |

Full architecture: [docs/architecture.md](docs/architecture.md).
Package source strategy (Nix vs Homebrew vs MAS):
[docs/packages.md](docs/packages.md).

## Verifying changes

```bash
# Eval check (no build) — evaluates every host via the flake's `checks`
# output, so it catches typos, type errors and missing files (~1 min cold).
# On a non-darwin machine add --all-systems.
cd ~/.dotfiles/nix && nix flake check --no-build

# Lane-hook and cc-tooling tests (bash, jq, git — no Nix needed)
~/.dotfiles/tests/run.sh

# Full apply
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
```

CI runs both checks on Linux, then a fresh-install test on macOS, on
every push ([docs/ci.md](docs/ci.md)).
If you change m5's brews, check the hardcoded formula list in
`.github/workflows/check.yml`'s smoke check.

## Development tools on these machines

- **Java & Node**: mise (`nix/home/mise.nix`) — global Temurin 25 and
  Node LTS; per project from `.java-version`/`.nvmrc`/`mise.toml`, with
  `JAVA_HOME` set on `cd`. A bare `21` in `.java-version` means OpenJDK,
  `temurin-21` means Temurin (see [docs/packages.md](docs/packages.md))
- **Kubernetes**: kubectl, helm, flux, kubeseal, kdoctor; aliases `k`,
  `kgp`, `kaf`, … from `nix/modules/environment.nix`
- **Editors**: NixVim (Catppuccin, LSP, Telescope, Treesitter),
  IntelliJ + IdeaVim, VSCode
