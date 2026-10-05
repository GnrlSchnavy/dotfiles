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

# Evaluate every host without building/applying (~1 min cold)
cd ~/.dotfiles/nix && nix flake check --no-build

# Lane-hook and cc-tooling tests
~/.dotfiles/tests/run.sh
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
6. `sudo nix run --inputs-from ~/.dotfiles/nix nix-darwin#darwin-rebuild -- switch --flake ~/.dotfiles/nix#<host>`
   — `darwin-rebuild` comes from the nix-darwin revision locked in `flake.lock`.
7. Prints post-install steps (`mise install` for the Java/Node
   versions). `~/.claude/settings.json` needs no step: the rebuild
   creates it from the repo snapshot.

## Maintenance scripts (`scripts/`)

| Script | What it does | When |
|---|---|---|
| `update.sh` | `git pull --ff-only` → `nix flake update` → `darwin-rebuild build` (restores the old lock if it fails) → `sudo darwin-rebuild switch` → commits `flake.lock` | when you want newer inputs before the weekly lock-update PR lands; push afterwards |
| `check.sh` | Health check: repo clean, flake evaluates, host descriptor exists, every home-manager symlink resolves, tooling on PATH, mise's configured versions installed | after a rebuild or when something feels off |
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

**"Refusing to load formula ... from untrusted tap"** — Homebrew
(mid-2026+) gates third-party taps behind explicit trust.
`nix/modules/homebrew-trust.nix` handles this declaratively: during
every activation it derives the tap list from the host's declared
brews/casks (`owner/tap/name` entries) and runs `brew trust` on each,
so rebuilds, fresh installs, and CI are all covered. If the error
still appears, the rebuild ran before the module landed on this
machine — pull and rebuild again, or `brew trust <owner>/<tap>` once
by hand.

**Brew bundle fails on one cask** — usually upstream; try
`brew install --cask <name>` for the real error, comment the cask out
temporarily if it's broken upstream.

**Pre-existing `~/.zshrc` etc. blocking home-manager** — shouldn't
happen: `backupFileExtension = "hm-backup"` renames blockers to
`*.hm-backup`. Inspect/delete those after verifying the new config.

**Rebuild succeeded but shell changes aren't visible** — restart the
terminal; `.zprofile`/`.zshenv` changes need a new login shell.

**Dock gone and Cmd-Tab dead after a rebuild** — activation kills the
Dock to apply `dock.nix`, and occasionally launchd fails to relaunch
it. Cmd-Tab is served by the Dock process, so both disappear together.
Restart it:
```bash
launchctl kickstart -k "gui/$(id -u)/com.apple.Dock.agent"
```
