# Operations

## The everyday loop

```bash
# 1. Edit config in ~/.dotfiles
# 2. Stage it — flakes only see git-tracked files
git add -A
# 3. Apply (system + user + homebrew in one shot; sudo is required)
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
```

Other common operations:

```bash
# Update all flake inputs, then rebuild
nix flake update --flake ~/.dotfiles/nix
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
# (commit the resulting flake.lock change)

# Roll back the last rebuild
sudo darwin-rebuild --rollback

# Evaluate without building/applying (fast sanity check)
cd ~/.dotfiles/nix && nix flake check --no-build
```

## Bootstrap a machine: `./setup.sh`

Idempotent; safe to re-run. Steps, in order:

1. Rosetta 2 (Apple Silicon) and Xcode CLT (exits and asks for a
   re-run if CLT was just triggered).
2. Clones the repo to `~/.dotfiles` (skips if present).
3. Verifies `nix/hosts/$(scutil --get LocalHostName)/default.nix`
   exists — if not, prints the new-host onboarding steps and exits
   (see [hosts.md](hosts.md)).
4. Installs Homebrew (nix-homebrew patches it later but needs the
   initial install) and Nix (multi-user daemon).
5. Moves pre-existing `/etc/nix/nix.conf`, `/etc/bashrc`, `/etc/zshrc`
   to `*.before-nix-darwin` so nix-darwin can take them over.
6. `sudo nix run github:LnL7/nix-darwin/nix-darwin-25.11#darwin-rebuild -- switch --flake ~/.dotfiles/nix#<host>`
   — pinned to the same nix-darwin release as `flake.nix`.
7. Seeds `~/.claude/settings.json` and `~/.claude-mem/settings.json`
   from the repo snapshots (only when absent; `/Users/<name>` paths
   rewritten to the current `$HOME`).
8. Prints post-install steps (jenv/nvm toolchain bootstrap).

## Maintenance scripts (`scripts/`)

| Script | What it does | When |
|---|---|---|
| `update.sh` | `git pull --ff-only` → `nix flake update` → `sudo darwin-rebuild switch` → PATH sanity check | weekly housekeeping. Note: it updates `flake.lock` but does not commit it — commit manually after a good rebuild |
| `check.sh` | Health check: repo clean, flake evaluates, host descriptor exists, every home-manager symlink resolves, tooling on PATH, `~/.jenv` / `~/.nvm` exist | after a rebuild or when something feels off |
| `backup.sh` | Dereferences managed symlinks + brew package lists + system versions into `~/.dotfiles_backup_<timestamp>/` with a restore script | before a big flake update or experiment |

None are required — `darwin-rebuild` does the real work.

## Troubleshooting

**"Unexpected files in /etc, aborting activation"** — pre-existing
`/etc/nix/nix.conf` / `/etc/bashrc` / `/etc/zshrc`. setup.sh handles
it; manually:
```bash
for f in /etc/nix/nix.conf /etc/bashrc /etc/zshrc; do
  [ -f "$f" ] && sudo mv "$f" "$f.before-nix-darwin"
done
```

**"path ... does not exist" during rebuild** — the file isn't
git-tracked. `git add` it and retry.

**`home.homeDirectory ... not of type 'absolute path'`** — the host
descriptor is missing `users.users.<name>.home = "/Users/<name>";`.

**A brew-installed tool keeps disappearing** — `cleanup = "zap"`
removes anything not declared in the host's `homebrew.nix`. Declare it
(see [packages.md](packages.md#-cleanup--zap)).

**Brew bundle fails on one cask** — usually upstream; try
`brew install --cask <name>` for the real error, comment the cask out
temporarily if it's broken upstream.

**Pre-existing `~/.zshrc` etc. blocking home-manager** — shouldn't
happen: `backupFileExtension = "hm-backup"` renames blockers to
`*.hm-backup`. Inspect/delete those after verifying the new config.

**Rebuild succeeded but shell changes aren't visible** — restart the
terminal; `.zprofile`/`.zshenv` changes need a new login shell.
