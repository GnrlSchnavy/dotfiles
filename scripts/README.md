# Maintenance Scripts

Helpers for the day-to-day care of this dotfiles setup. None of them
are required — `darwin-rebuild` does the heavy lifting — but they
package up common workflows.

## `update.sh`

Pull the repo, refresh flake inputs, rebuild against the current host,
sanity-check the toolchain.

```bash
./scripts/update.sh
```

Equivalent to running:

```bash
git pull --ff-only
nix flake update --flake ./nix
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName)
```

with status output in between.

## `check.sh`

Health check. Verifies:

- Repo is at `~/.dotfiles`, branch is clean
- `nix`, `darwin-rebuild`, `brew` are on PATH
- A host descriptor exists for this machine
- Every home-manager-managed symlink resolves
- Common tooling (`git`, `kubectl`, `nvim`, etc.) is reachable
- Version-manager directories (`~/.jenv`, `~/.nvm`, `~/.pyenv`) exist

Run it after a rebuild or whenever something feels off.

```bash
./scripts/check.sh
```

## `backup.sh`

Snapshots the current state (dotfile contents, Homebrew package lists,
macOS / nix-darwin versions) into `~/.dotfiles_backup_<timestamp>/`.
Symlinks are dereferenced so the backup is portable.

```bash
./scripts/backup.sh
```

Useful before a major flake update or experiment.

## When to use which

| Scenario | Script |
|---|---|
| Weekly housekeeping | `update.sh` |
| Something's broken | `check.sh`, then `update.sh` |
| About to try a big change | `backup.sh` first |
| Set up a new Mac | use `setup.sh` (root of repo), not these |
