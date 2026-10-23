# macOS Dotfiles

[![fresh-install test](https://github.com/GnrlSchnavy/dotfiles/actions/workflows/check.yml/badge.svg)](https://github.com/GnrlSchnavy/dotfiles/actions/workflows/check.yml)

A reproducible macOS development environment. One `darwin-rebuild switch`
applies the entire system: packages, dock, keyboard, shell, git, editor
configs — everything.

Built on three layers:

| Layer | Manages | Mechanism |
|---|---|---|
| **nix-darwin** | macOS system: defaults, dock, launchd, fonts, packages | `nix/modules/*.nix` (shared) + `nix/profiles/<role>/*.nix` + `nix/hosts/<name>/*.nix` |
| **home-manager** | User-level dotfiles: `.zshrc`, `.gitconfig`, `.ideavimrc`, `.claude/*` | `nix/home/*.nix` (shared) + `nix/profiles/<role>/*.nix` |
| **nix-homebrew** | GUI applications and a few CLI tools that aren't in nixpkgs | `nix/profiles/<role>/homebrew.nix` |

Each Mac plays one role. Its host descriptor lists **profiles**
([`nix/profiles/`](nix/profiles/README.md)): `dev` everywhere (dev
apps, CLI tools, Colima as the Docker engine) plus `personal` (`m5`) or
`work` (the client-issued Mac).

No Stow. No manual symlink dance. CI verifies a fresh-install scenario
end-to-end on every push.

---

## Quick start (existing host)

If your machine's hostname already has a descriptor in
[`nix/hosts/`](nix/hosts/) (e.g. `m5`):

```bash
git clone https://github.com/GnrlSchnavy/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./setup.sh
```

`setup.sh` will:

1. Install Rosetta 2 + Xcode CLI tools (skipped if present)
2. Install Homebrew + Nix (skipped if present)
3. Move any pre-existing `/etc/{nix.conf,bashrc,zshrc}` aside
4. Bootstrap nix-darwin and apply the host config in one command

After it finishes, restart your terminal and run the
[post-install steps](#post-install-steps) below.

## Setting up a new host

The config is parameterized by a per-host descriptor. Onboarding a new
Mac is four steps:

```bash
# 1. Copy the template (run inside the new Mac, after cloning)
cp -r nix/hosts/template "nix/hosts/$(scutil --get LocalHostName)"

# 2. Edit the new descriptor — replace the REPLACE_ME_* placeholders and
#    pick its profiles ("dev" plus one of "personal" / "work"); seed a
#    dock with: cp nix/hosts/m5/dock.nix nix/hosts/<your-hostname>/
$EDITOR "nix/hosts/$(scutil --get LocalHostName)/default.nix"

# 3. Register it in nix/flake.nix's `hosts` attrset:
#    hosts = {
#      m5 = import ./hosts/m5;
#      <your-hostname> = import ./hosts/<your-hostname>;
#    };

# 4. Stage and commit (Nix flakes only see git-tracked files)
git add nix/hosts/<your-hostname>/ nix/flake.nix
git commit -m "host: add <your-hostname>"

# Then run setup.
./setup.sh
```

## Post-install steps

Everything else is declared, so only the two sign-ins are left, once per
machine (`setup.sh` prints the same list):

```bash
pass-cli login    # Proton Pass: the source of every runtime secret (docs/secrets.md)
devai setup       # work machine only: gateway sign-in, after installing the DevAI CLI (docs/claude-code.md)
```

The rebuild installs mise's Java/Node versions, and Claude Code fetches
the declared plugins (codemem included) when a session first starts.

---

## Daily operations

```bash
# Apply a config change (works for system, user, or homebrew changes)
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#${DOTFILES_HOST:-$(scutil --get LocalHostName)} -v

# Newer flake inputs: CI opens a tested PR (weekly, or now with this);
# merge it once green, then pull, review and apply
gh workflow run update-flake-lock.yml
~/.dotfiles/scripts/update.sh

# Ship your own committed change: master only takes PRs (docs/ci.md)
dotpr

# Roll back if a rebuild went sideways
sudo darwin-rebuild --rollback
```

### Where to add or edit things

| What | Where |
|---|---|
| New CLI tool from nixpkgs | [`nix/profiles/<role>/packages.nix`](nix/profiles/dev/packages.nix) |
| New GUI app (cask) or brew formula | [`nix/profiles/<role>/homebrew.nix`](nix/profiles/dev/homebrew.nix) |
| Docker engine (Colima) | [`nix/profiles/dev/docker.nix`](nix/profiles/dev/docker.nix) |
| macOS system default (finder, keyboard, etc.) | [`nix/modules/system.nix`](nix/modules/system.nix) |
| Dock layout / apps (per-host) | [`nix/hosts/<name>/dock.nix`](nix/hosts/m5/dock.nix) |
| Shell config (zsh init, env vars) | [`nix/home/zsh.nix`](nix/home/zsh.nix) |
| Java/Node versions (mise) | [`nix/home/mise.nix`](nix/home/mise.nix) |
| Claude Code settings merge, `CLAUDE.md`, agents/commands | [`nix/home/claude-code.nix`](nix/home/claude-code.nix) |
| Claude Code, personal (Max, sandbox, plugins) / work (`cc-work`, gateway check) | [`nix/profiles/personal/claude.nix`](nix/profiles/personal/claude.nix) / [`nix/profiles/work/claude.nix`](nix/profiles/work/claude.nix) |
| codemem memory | [`nix/home/codemem.nix`](nix/home/codemem.nix) |
| Git config (personal identity by default; work in the `work` profile) | [`nix/home/git.nix`](nix/home/git.nix) |
| New dotfile to symlink (e.g. `.foorc`) | [`nix/home/files.nix`](nix/home/files.nix) |
| Neovim plugins / LSP / keymaps | [`nix/nixvim/config/`](nix/nixvim/config/) |
| Garbage collection, nix daemon settings | [`nix/modules/nix.nix`](nix/modules/nix.nix) |

After any edit: `git add` the change (flakes need it staged) and rebuild.

---

## Repository layout

```
.
├── nix/
│   ├── flake.nix              ← input plumbing + per-host wiring
│   ├── flake.lock             ← pinned versions of all inputs
│   ├── profiles/              ← one per role; a host lists the ones it gets
│   │   ├── dev/               ← every machine: dev apps/CLI, Colima Docker engine
│   │   ├── personal/          ← m5: personal apps, Claude Max + sandbox, vault skills
│   │   └── work/              ← work Mac: work apps + git identity, Claude via DevAI
│   ├── hosts/
│   │   ├── m5/                ← personal Mac: descriptor (profiles) + dock
│   │   ├── work/              ← client-issued Mac: descriptor + dock
│   │   ├── ci/                ← CI runner descriptor (mirrors m5)
│   │   └── template/          ← copy this when adding a new host
│   ├── modules/               ← shared nix-darwin (system-level) modules
│   │   ├── system.nix         ← macOS defaults (keyboard, finder, login window), Touch ID sudo
│   │   ├── environment.nix    ← system-wide env vars and aliases
│   │   ├── nix.nix            ← nix daemon config (gc, optimise, settings)
│   │   ├── homebrew.nix       ← Homebrew on, onActivation (cleanup = "zap")
│   │   └── homebrew-trust.nix ← brew trust for declared third-party taps
│   ├── home/                  ← shared home-manager (user-level) modules
│   │   ├── default.nix        ← entrypoint, imports submodules
│   │   ├── zsh.nix            ← .zshrc / .zprofile / .zshenv content
│   │   ├── mise.nix           ← Java/Node via mise (global versions)
│   │   ├── git.nix            ← git config, personal identity by default
│   │   ├── files.nix          ← file-pointer dotfiles (.ideavimrc)
│   │   ├── secrets.nix        ← Proton Pass helpers (pass-get, pass-render)
│   │   ├── claude-code.nix    ← Claude Code plumbing: settings merge, CLAUDE.md, agents
│   │   └── codemem.nix        ← codemem lane + observer config
│   └── nixvim/                ← neovim configuration as a nix module
│       └── config/            ← imported by flake.nix's per-host nvim build
│
├── editors/.ideavimrc         ← IntelliJ Vim config (referenced by home/files.nix)
├── system/.claude/            ← Claude Code: settings snapshot, CLAUDE.md, agents,
│                                 commands, skills (home/claude-code.nix + profiles)
├── system/claude-work/        ← work profile: hooks + Ahold CLAUDE.md overlay
├── system/bin/                ← settings merge, claude-git-ssh, cc-tooling
│
├── .github/workflows/check.yml ← Linux eval + tests, then fresh-install CI
├── setup.sh                    ← bootstrap entry point
├── scripts/                    ← maintenance helpers (check, update, backup, lint)
└── tests/                      ← gateway-check, subagent, cc-tooling, settings-merge and doc-drift tests (tests/run.sh)
```

---

## CI: fresh-install verification

[`.github/workflows/check.yml`](.github/workflows/check.yml) first
evaluates every host and runs `tests/run.sh` on Linux (~2 min), then
runs the full bootstrap on a clean macOS 27 GitHub-hosted runner
against the `ci` host descriptor. It catches:

- Nix evaluation errors (typos, wrong types, missing imports)
- Build failures in any package
- Activation script errors
- Home-manager activation issues
- Brew bundle failures (formulas only — see caveats)

Runs ~10–15 min per push. The smoke check at the end verifies every
managed symlink exists and key brew formulas are installed.

### Caveats

- **Casks aren't tested in CI.** A few have DSL incompatibilities
  with the runner image's Homebrew that don't reproduce on
  real Macs. The CI host overrides `homebrew.casks = []`.
- **Same macOS major, not the same machine.** The runner is macOS 27 on
  Apple Silicon, like the real host, but it's a fresh image: anything
  that depends on local state (the Keychain, an existing Homebrew,
  app-specific security prompts) only shows up on the Mac itself.

---

## Troubleshooting

**`Unexpected files in /etc, aborting activation`** on a fresh
machine — pre-existing `/etc/nix/nix.conf`, `/etc/bashrc`, or
`/etc/zshrc`. `setup.sh` handles this; if you're invoking
`darwin-rebuild` manually:
```bash
for f in /etc/nix/nix.conf /etc/bashrc /etc/zshrc; do
  [ -f "$f" ] && sudo mv "$f" "$f.before-nix-darwin"
done
```

**`A definition for option ... home.homeDirectory is not of type 'absolute path'`** —
the host descriptor is missing `users.users.<name>.home = "/Users/<name>"`.
home-manager's common.nix derives `home.homeDirectory` from there.

**Hostname not matching a descriptor** — `setup.sh` will tell you
exactly what to do (it's [the new-host workflow](#setting-up-a-new-host)).

**Brew bundle fails on a specific cask** — usually an upstream
Homebrew issue (we've seen them on macOS 26). Check
`brew install --cask <name>` manually for the real error. If it's
truly broken upstream, comment the cask out of the profile's
`homebrew.nix` (`nix/profiles/<role>/homebrew.nix`) temporarily.

**Pre-existing `~/.zshrc` etc. blocking home-manager** — the flake
sets `home-manager.backupFileExtension = "hm-backup"`, so your
existing files get renamed (e.g. `~/.zshrc.hm-backup`) instead of
blocking activation. Inspect/delete after you're satisfied with the
new config.

---

## Requirements

- macOS 15+ (developed on macOS 27)
- Apple Silicon (Intel works for most of it; the host descriptors
  declare `aarch64-darwin` — change to `x86_64-darwin` for Intel)
- Admin privileges (nix-darwin activation requires sudo)
- An internet connection (initial run pulls a few GB through the cache)
- ~10 GB free disk for the nix closure and homebrew downloads

---

## Documentation

Canonical docs live in [`docs/`](docs/):

- [`docs/architecture.md`](docs/architecture.md) — flake wiring, module layering, profiles, host descriptors
- [`docs/hosts.md`](docs/hosts.md) — host inventory and new-host onboarding
- [`docs/packages.md`](docs/packages.md) — Nix vs Homebrew vs MAS strategy, adding/removing packages
- [`docs/shell-and-dotfiles.md`](docs/shell-and-dotfiles.md) — zsh setup, dotfile symlinking, files apps rewrite at runtime
- [`docs/claude-code.md`](docs/claude-code.md) — Claude Code per profile (personal Max / work DevAI), Docker (Colima), codemem memory
- [`docs/agent-workflow.md`](docs/agent-workflow.md) — the `/flow` multi-agent workflow
- [`docs/client-tooling.md`](docs/client-tooling.md) — per-client tooling (`cc-tooling`) and onboarding a client
- [`docs/secrets.md`](docs/secrets.md) — Proton Pass references and helpers
- [`docs/operations.md`](docs/operations.md) — rebuilds, updates, maintenance scripts, troubleshooting
- [`docs/ci.md`](docs/ci.md) — the fresh-install CI workflow

Plus [`CLAUDE.md`](CLAUDE.md) — entry point for AI agents working in this repo.
