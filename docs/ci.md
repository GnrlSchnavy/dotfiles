# CI: fresh-install test

[`.github/workflows/check.yml`](../.github/workflows/check.yml) runs
on every push/PR to `master` (plus manual dispatch). It replays what
`setup.sh` does on a real Mac against the `ci` host descriptor on a
GitHub-hosted `macos-15` runner (~10–15 min).

## What it does

1. **Install Nix** (`cachix/install-nix-action`) with flakes enabled
   and a GitHub token for input fetches (avoids anonymous rate
   limits).
2. **Use the `nix-community` cache** (`cachix-action`, `skipPush`) for
   nixvim/home-manager artifacts not on cache.nixos.org.
3. **Move `/etc/nix/nix.conf`, `/etc/bashrc`, `/etc/zshrc` aside** —
   same step setup.sh performs.
4. **`sudo nix run nix-darwin#darwin-rebuild -- switch --flake ./nix#ci`**.
   The GitHub token is passed via `--option access-tokens` because the
   nix.conf that held it was just moved aside, and sudo's root HOME
   doesn't see the user-level config.
5. **Smoke checks**: PATH is prepended with
   `/run/current-system/sw/bin` and the per-user profile, then it
   asserts the home-manager symlinks exist (`~/.zshrc`, `~/.zprofile`,
   `~/.zshenv`, `~/.config/git/{config,ignore}`, `~/.ideavimrc`,
   `~/.claude/settings.local.json`), `darwin-rebuild` and `brew` are on
   PATH, and the formulas `jenv`, `kubectl`, `helm` are installed.

## The `ci` host (`nix/hosts/ci/default.nix`)

Mirrors m5 by importing `../m5/{homebrew,packages,dock}.nix` and
`../m5/git.nix`, then overrides for CI:

- `homebrew.casks = lib.mkForce [ ]` — casks are multi-GB and a few
  have DSL incompatibilities with the runner's Homebrew; brews alone
  exercise the brew-bundle path.
- `homebrew.onActivation.cleanup = lib.mkForce "none"` — don't zap the
  runner's pre-installed packages.
- `homebrew.onActivation.upgrade = lib.mkForce false` — nothing to
  upgrade on a fresh runner; avoids unrelated upstream failures.
- `username = "runner"`, home `/Users/runner`.

## What CI catches / misses

Catches: Nix eval errors, package build failures, activation script
errors, home-manager activation problems, brew formula issues.

Misses:

- **Cask problems** (casks are dropped in CI).
- **macOS version drift** — runner is macOS 15, real machines run
  macOS 26. Switch `runs-on:` when `macos-26` runners ship.
- Less than it used to: CI now mirrors `m5`, the only real host, so
  the old gap where an m5-only typo passed CI is gone.

## Maintenance couplings

- The smoke check hardcodes formulas `jenv kubectl helm`. If m5's
  brews change, update the workflow list.
- The smoke check's symlink list must track `nix/home/files.nix` —
  add a check when adding an important managed file.
- The bootstrap pins `github:LnL7/nix-darwin/nix-darwin-25.11`; keep
  it in sync with the `nix-darwin` input in `nix/flake.nix` (setup.sh
  has the same pin).
