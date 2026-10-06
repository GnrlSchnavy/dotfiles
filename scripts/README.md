# Maintenance Scripts

Helpers for the day-to-day care of this dotfiles setup. None of them
are required — `darwin-rebuild` does the heavy lifting — but they
package up common workflows. See
[`docs/operations.md`](../docs/operations.md) for the full operations
guide.

## `update.sh`

Pull the repo, refresh flake inputs, build, then switch — and commit
`nix/flake.lock` once the switch succeeds (push it yourself).

```bash
./scripts/update.sh
```

It stops if the pull fails, and builds before switching: if the build
fails nothing is applied and the previous `flake.lock` is restored. Roughly:

```bash
git pull --ff-only
nix flake update --flake ./nix
darwin-rebuild build --flake ~/.dotfiles/nix#$(scutil --get LocalHostName)
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName)
git commit -m "flake: update inputs" -- nix/flake.lock
```

Inputs are also bumped weekly by CI as a pull request (see
[`docs/ci.md`](../docs/ci.md)); merging that and pulling is the
low-effort path.

## `check.sh`

Health check. Verifies:

- Repo is at `~/.dotfiles`, branch is clean
- `nix`, `darwin-rebuild`, `brew` are on PATH
- A host descriptor exists for this machine
- Every home-manager-managed symlink resolves
- Common tooling (`git`, `kubectl`, `nvim`, etc.) is reachable
- mise is on PATH and its configured Java/Node versions are installed

Run it after a rebuild or whenever something feels off.

```bash
./scripts/check.sh
```

## `backup.sh`

Copies the state git can't regenerate into
`~/.dotfiles-backups/<timestamp>/` (owner-only, since some of it can
hold credentials):

- both lanes' `settings.json` and `.claude.json` (app-owned)
- the codemem memory databases (`~/.codemem/*/mem.sqlite`, via
  `sqlite3 .backup` so a running observer doesn't corrupt the copy)
- `~/.docker/config.json`
- Homebrew package lists, macOS / nix-darwin versions, the repo commit

Managed dotfiles are skipped: a rebuild recreates them. The newest five
backups are kept (`BACKUP_KEEP=10 ./scripts/backup.sh` keeps more). Each
has a README with the restore commands.

```bash
./scripts/backup.sh
```

Useful before a major flake update or experiment.

## `lint.sh`

nixfmt, statix, deadnix and shellcheck over the repo, plus a gitleaks
scan of the working tree (the repo is public). Runs inside
`nix develop ./nix` on its own if the tools aren't on PATH.

```bash
./scripts/lint.sh
(cd nix && nix fmt)  # fixes what nixfmt flags (formats every .nix file)
```

The pre-commit hook in `.githooks/` runs it before every commit in
either dotfiles clone (`core.hooksPath`, set by the host's `git.nix`);
CI runs it too. Skip it once with `git commit --no-verify`.

## When to use which

| Scenario | Script |
|---|---|
| Weekly housekeeping | `update.sh` |
| Something's broken | `check.sh`, then `update.sh` |
| About to try a big change | `backup.sh` first |
| Set up a new Mac | use `setup.sh` (root of repo), not these |
