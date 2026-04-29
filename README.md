# macOS Dotfiles

[![fresh-install test](https://github.com/GnrlSchnavy/dotfiles/actions/workflows/check.yml/badge.svg)](https://github.com/GnrlSchnavy/dotfiles/actions/workflows/check.yml)

A reproducible macOS development environment. One `darwin-rebuild switch`
applies the entire system: packages, dock, keyboard, shell, git, editor
configs — everything.

Built on three layers:

| Layer | Manages | Mechanism |
|---|---|---|
| **nix-darwin** | macOS system: defaults, dock, launchd, fonts, packages | `nix/modules/*.nix` |
| **home-manager** | User-level dotfiles: `.zshrc`, `.gitconfig`, `.ideavimrc`, `.claude/*` | `nix/home/*.nix` |
| **nix-homebrew** | GUI applications and a few CLI tools that aren't in nixpkgs | `nix/modules/homebrew.nix` |

No Stow. No manual symlink dance. CI verifies a fresh-install scenario
end-to-end on every push.

---

## Quick start (existing host)

If your machine's hostname already has a descriptor in
[`nix/hosts/`](nix/hosts/) (e.g. `m4`):

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

# 2. Edit the new descriptor — replace the REPLACE_ME_* placeholders
$EDITOR "nix/hosts/$(scutil --get LocalHostName)/default.nix"

# 3. Register it in nix/flake.nix's `hosts` attrset:
#    hosts = {
#      m4 = import ./hosts/m4;
#      <your-hostname> = import ./hosts/<your-hostname>;
#    };

# 4. Stage and commit (Nix flakes only see git-tracked files)
git add nix/hosts/<your-hostname>/ nix/flake.nix
git commit -m "host: add <your-hostname>"

# Then run setup.
./setup.sh
```

## Post-install steps

The setup installs version managers (`jenv`, `nvm`, `pyenv`) but not
the language toolchains they manage. Bootstrap whichever you need:

```bash
# Java: install a JDK (e.g. via `brew install temurin@25`), then point jenv at it
jenv add /Library/Java/JavaVirtualMachines/temurin-25.jdk/Contents/Home
jenv global temurin-25

# Node
nvm install --lts

# Python
pyenv install 3.13
pyenv global 3.13
```

---

## Daily operations

```bash
# Apply a config change (works for system, user, or homebrew changes)
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v

# Update all flake inputs (nixpkgs, nix-darwin, home-manager, etc.)
nix flake update --flake ~/.dotfiles/nix
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v

# Roll back if a rebuild went sideways
sudo darwin-rebuild --rollback
```

### Where to add or edit things

| What | Where |
|---|---|
| New CLI tool from nixpkgs | [`nix/modules/packages.nix`](nix/modules/packages.nix) |
| New GUI app (cask) or brew formula | [`nix/modules/homebrew.nix`](nix/modules/homebrew.nix) |
| macOS system default (dock, finder, etc.) | [`nix/modules/system.nix`](nix/modules/system.nix) or [`nix/modules/dock.nix`](nix/modules/dock.nix) |
| Shell config (zsh init, lazy-loads, env vars) | [`nix/home/zsh.nix`](nix/home/zsh.nix) |
| Git config | [`nix/home/git.nix`](nix/home/git.nix) |
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
│   ├── hosts/
│   │   ├── m4/                ← descriptor for the "m4" Mac (hostname, user)
│   │   ├── ci/                ← CI runner descriptor (used by the workflow)
│   │   └── template/          ← copy this when adding a new host
│   ├── modules/               ← nix-darwin (system-level) modules
│   │   ├── packages.nix       ← Nix-managed CLI tools
│   │   ├── homebrew.nix       ← brew bundle (casks, formulas, MAS)
│   │   ├── system.nix         ← macOS defaults (keyboard, finder, login window)
│   │   ├── dock.nix           ← dock layout and behavior
│   │   ├── environment.nix    ← system-wide env vars and aliases
│   │   └── nix.nix            ← nix daemon config (gc, optimise, settings)
│   ├── home/                  ← home-manager (user-level) modules
│   │   ├── default.nix        ← entrypoint, imports submodules
│   │   ├── git.nix            ← programs.git config + global ignores
│   │   ├── zsh.nix            ← .zshrc / .zprofile / .zshenv content
│   │   └── files.nix          ← file-pointer dotfiles (.ideavimrc, .docker, .claude)
│   └── nixvim/                ← neovim configuration as a nix module
│       └── config/            ← imported by flake.nix's per-host nvim build
│
├── editors/.ideavimrc         ← IntelliJ Vim config (referenced by home/files.nix)
├── development/.docker/       ← Docker CLI config (referenced by home/files.nix)
├── system/.claude/            ← Claude Code settings (referenced by home/files.nix)
│
├── .github/workflows/check.yml ← fresh-install CI
├── setup.sh                    ← bootstrap entry point
└── scripts/                    ← maintenance helpers (check, update, backup)
```

---

## CI: fresh-install verification

[`.github/workflows/check.yml`](.github/workflows/check.yml) runs the
full bootstrap on a clean macOS-15 GitHub-hosted runner against the
`ci` host descriptor. It catches:

- Nix evaluation errors (typos, wrong types, missing imports)
- Build failures in any package
- Activation script errors
- Home-manager activation issues
- Brew bundle failures (formulas only — see caveats)

Runs ~10–15 min per push. The smoke check at the end verifies every
managed symlink exists and key brew formulas are installed.

### Caveats

- **Casks aren't tested in CI.** A few have DSL incompatibilities
  with the macos-15 runner image's Homebrew that don't reproduce on
  real Macs. The CI host overrides `homebrew.casks = []`.
- **macOS version mismatch.** Runner is macOS 15; the production
  host runs macOS 26. A Tahoe-specific upstream bug wouldn't be
  caught. When GitHub ships `macos-26` runners, switch the
  `runs-on:` field.

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
truly broken upstream, comment the cask out of `homebrew.nix`
temporarily.

**Pre-existing `~/.zshrc` etc. blocking home-manager** — the flake
sets `home-manager.backupFileExtension = "hm-backup"`, so your
existing files get renamed (e.g. `~/.zshrc.hm-backup`) instead of
blocking activation. Inspect/delete after you're satisfied with the
new config.

---

## Requirements

- macOS 15+ (developed on macOS 26 / Tahoe)
- Apple Silicon (Intel works for most of it; the `m4` host descriptor
  declares `aarch64-darwin` — change to `x86_64-darwin` for Intel)
- Admin privileges (nix-darwin activation requires sudo)
- An internet connection (initial run pulls a few GB through the cache)
- ~10 GB free disk for the nix closure and homebrew downloads

---

## Documentation

- [`CLAUDE.md`](CLAUDE.md) — guidance for Claude Code when working in this repo
- [`nix/PACKAGE-STRATEGY.md`](nix/PACKAGE-STRATEGY.md) — when to pick Nix vs Homebrew vs MAS
- [`nix/modules/README.md`](nix/modules/README.md) — per-module overview
- [`scripts/README.md`](scripts/README.md) — maintenance script catalog
