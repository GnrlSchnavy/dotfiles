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

Each Mac plays one role, picked by the **profiles** its host descriptor
lists ([`nix/profiles/`](nix/profiles/README.md)): `dev` on every
machine plus exactly one of `personal` / `work`. Hosts: `m5` (user
`yvan`) is the personal Mac and does no client work; `work` is the
client-issued Mac (user `pnl1ln25`, selected with `DOTFILES_HOST=work`); `ci` mirrors
m5 for the fresh-install CI test. See [docs/hosts.md](docs/hosts.md).

## The one command

```bash
# Applies system + user + homebrew config in one shot. sudo required.
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#${DOTFILES_HOST:-$(scutil --get LocalHostName)} -v
```

Fresh machine bootstrap: `./setup.sh`
([docs/operations.md](docs/operations.md)). After the first rebuild,
once per machine, only the sign-ins: `pass-cli login` and (work
machine) `devai setup`. Java/Node (mise) install during the rebuild;
Claude Code plugins, codemem included, are declared in the profiles'
`claude.nix`. Keep it
that way: prefer an activation step or a declared setting over a manual
post-install step.

## Hard rules (violations break the build or the machine)

1. **`git add` every new/changed file before rebuilding** — Nix flakes
   only read git-tracked files; untracked files cause
   "path does not exist" errors.
2. **`darwin-rebuild switch` needs `sudo`.**
3. **Never symlink files that apps rewrite at runtime**:
   `~/.claude/settings.json`, `~/.docker/config.json`. Claude Code's
   settings use a reference snapshot plus an activation-time merge of
   owned keys instead — see
   [docs/shell-and-dotfiles.md](docs/shell-and-dotfiles.md#files-that-must-not-be-symlinked).
4. **`homebrew.onActivation.cleanup = "zap"`** — any brew/cask not
   declared for the host (its profiles' `homebrew.nix`) is uninstalled
   on rebuild (`nix/modules/homebrew.nix`).
   Removing a line is how software gets uninstalled; manual
   `brew install`s don't survive.
5. **Profiles vs hosts vs shared**: role-level config (apps, packages,
   git identity, Claude Code backend) → `nix/profiles/<role>/`;
   machine-only config (dock, hostname, username) → `nix/hosts/<name>/`;
   everything shared → `nix/modules/` (system) or `nix/home/` (user).
   Don't put role- or host-specific config in shared modules, and never
   give one host both `personal` and `work` — client content must never
   reach the personal Max login.
6. **Python is not centrally managed.** pyenv was deliberately removed
   (June 2026) — don't reintroduce pyenv into brews, zsh.nix, scripts,
   or docs.

## Where things live

| Change | File |
|---|---|
| Which profiles a host gets | `nix/hosts/<name>/default.nix` ([nix/profiles/README.md](nix/profiles/README.md)); what each profile installs and does: [docs/profiles.md](docs/profiles.md) — keep it in sync (`tests/docs.sh`) |
| CLI tool (nixpkgs) | `nix/profiles/<role>/packages.nix` (`dev` = every machine) |
| GUI app / brew formula | `nix/profiles/<role>/homebrew.nix` |
| Docker engine (Colima), `DOCKER_HOST` | `nix/profiles/dev/docker.nix` ([docs/claude-code.md](docs/claude-code.md#docker-colima)) |
| Dock apps | `nix/hosts/<name>/dock.nix` |
| Git config / ignores (personal identity by default) | `nix/home/git.nix`; work identity in `nix/profiles/work/git.nix` |
| Homebrew activation (`zap`) | `nix/modules/homebrew.nix` |
| macOS defaults | `nix/modules/system.nix` |
| Shell (zsh) init, env vars | `nix/home/zsh.nix` |
| Java/Node versions (mise) | `nix/home/mise.nix` |
| New dotfile symlink | `nix/home/files.nix` |
| Secrets (Proton Pass refs, `pass-get`/`pass-render`) | `nix/home/secrets.nix` ([docs/secrets.md](docs/secrets.md)) |
| Claude Code plumbing: settings merge (`dotfiles.claude.settings`), `CLAUDE.md` overlays, agents/commands links | `nix/home/claude-code.nix` ([docs/claude-code.md](docs/claude-code.md#shared-plumbing)) |
| SSH keys (Proton Pass agent, `~/.ssh/config`; vault + hosts + public keys per profile) | `nix/home/ssh.nix`, `nix/profiles/*/ssh.nix` + `ssh/*.pub` ([docs/ssh.md](docs/ssh.md)) |
| Claude Code, personal: Max, Bash sandbox, plugins; vault skills | `nix/profiles/personal/{claude,vault}.nix` ([docs/claude-code.md](docs/claude-code.md#personal-profile)) |
| Git push/pull from Claude's Bash sandbox (every host) | `nix/home/sandbox-git.nix` ([docs/claude-code.md](docs/claude-code.md#git-pushpull-from-the-sandbox)) |
| Claude Code, work: `cc-work`/`cc-work-desktop` (DevAI), gateway check, model aliases, `cc-tooling` | `nix/profiles/work/claude.nix` ([docs/claude-code.md](docs/claude-code.md#work-profile)) |
| codemem memory (`dotfiles.codemem.lane`/`.observer`, set by the profiles) | `nix/home/codemem.nix` ([docs/claude-code.md](docs/claude-code.md#codemem-memory)) |
| Claude Code settings snapshot, agents/commands/skills, global `CLAUDE.md` | `system/.claude/` ([docs/claude-code.md](docs/claude-code.md)) |
| Work hooks + Ahold `CLAUDE.md` overlay | `system/claude-work/` ([docs/claude-code.md](docs/claude-code.md#work-profile)) |
| Agent workflow (`/flow`, roles, model tiers) | `system/.claude/agents/` + `commands/flow*.md` ([docs/agent-workflow.md](docs/agent-workflow.md)) |
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

# Gateway-check, subagent, cc-tooling, settings-merge and doc-drift tests
# (bash, jq, git — no Nix needed)
~/.dotfiles/tests/run.sh

# Lint: nixfmt, statix, deadnix, shellcheck, gitleaks (also the pre-commit
# hook in .githooks/, enabled by git.nix). Fix formatting with `cd nix && nix fmt`.
~/.dotfiles/scripts/lint.sh

# Full apply
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#${DOTFILES_HOST:-$(scutil --get LocalHostName)} -v
```

CI runs both checks on Linux, then a fresh-install test on macOS, on
every push ([docs/ci.md](docs/ci.md)).
If you change the `dev` or `personal` brews (CI mirrors m5), check the
hardcoded formula list in
`.github/workflows/check.yml`'s smoke check.

## Development tools on these machines

- **Java & Node**: mise (`nix/home/mise.nix`) — global Temurin 25
  (default) and 21, and Node LTS; per project from `.java-version`/`.nvmrc`/`mise.toml`, with
  `JAVA_HOME` set on `cd`. A bare `21` in `.java-version` means OpenJDK,
  `temurin-21` means Temurin (see [docs/packages.md](docs/packages.md))
- **Kubernetes**: kubectl, helm, flux, kubeseal; aliases `k`,
  `kgp`, `kaf`, … from `nix/modules/environment.nix`
- **Editors**: NixVim (Catppuccin, LSP, Telescope, Treesitter),
  IntelliJ + IdeaVim, VSCode
