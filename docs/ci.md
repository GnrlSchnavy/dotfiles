# CI: fresh-install test

[`.github/workflows/check.yml`](../.github/workflows/check.yml) runs
on every push/PR to `master` (plus manual dispatch). Two jobs:

1. **`checks`** (Linux, ~2 min) — `nix flake check --no-build
   --all-systems ./nix` evaluates every host (evaluation works
   cross-platform), [`scripts/lint.sh`](../scripts/lint.sh) in the
   flake's dev shell (nixfmt, statix, deadnix, shellcheck, and a
   gitleaks scan of the tree, since the repo is public),
   [`scripts/check-brew.sh`](../scripts/check-brew.sh) (no cask or
   formula Homebrew has disabled — the fresh install drops casks, so it
   can't catch those), and
   [`tests/run.sh`](../tests/run.sh): the gateway-check fixtures, the
   subagent-definition check, the `cc-tooling` and settings-merge tests,
   and the doc-drift check (the architecture map matches `nix/`, and
   `docs/profiles.md` names every app and brew the profiles declare).
2. **`fresh-install`** (macOS, needs `checks`) — runs `setup.sh`
   itself, once per role in parallel: against the `ci` host (m5's
   profiles) and the `ci-work` host (the work Mac's), each on a
   GitHub-hosted `xcode-27` runner: macOS 27 on Apple Silicon, in
   public preview (~10–15 min). GitHub names macOS images after their
   Xcode version now; `macos-26` is the GA fallback if the preview
   image queues or misbehaves. Described below.

## What the fresh-install job does

1. **Install Nix** (`cachix/install-nix-action`) with flakes enabled
   and a GitHub token for input fetches (avoids anonymous rate
   limits).
2. **Use the `nix-community` cache** (`cachix-action`, `skipPush`) for
   nixvim/home-manager artifacts not on cache.nixos.org.
3. **Run `./setup.sh` itself** with `DOTFILES_DIR` set to the checkout
   and `DOTFILES_HOST` set to the job's host (`ci` or `ci-work`). Xcode CLT, Homebrew and Nix are already on
   the runner, so it skips those installers; it moves
   `/etc/nix/nix.conf`, `/etc/bashrc`, `/etc/zshrc` aside and applies
   the flake via `--inputs-from`. The GitHub token reaches the root
   `nix run` through `NIX_CONFIG` (setup.sh passes it through sudo),
   because the nix.conf that held it was just moved aside.
4. **Smoke checks**: PATH is prepended with
   `/run/current-system/sw/bin` and the per-user profile, then it
   asserts:
   - the home-manager symlinks exist (`~/.zshrc`, `~/.zprofile`,
     `~/.zshenv`, `~/.config/git/{config,ignore}`, `~/.ideavimrc`);
   - Claude Code: `~/.claude/settings.json` is a regular file with
     codemem declared (the merged keys); then per role —
     - `ci` (personal): the sandbox is enabled, `~/.codemem/personal`
       exists, and the vault path was filled into the skills;
     - `ci-work` (work): the gateway-check hook is merged in and
       executable, `skipWebFetchPreflight` is set, `~/.codemem/work`
       exists, `cc-work` is defined, and `cc-tooling`, `az` and
       `kubelogin` are on PATH;
   - `darwin-rebuild`, `brew` and `mise` (with its config) are in
     place, macOS's `java_home` lists mise's Temurin 25 and 21, the
     tapped formulas `flux` and `pass-cli` are installed, and nixpkgs'
     `kubectl`, `helm` and `gh` are on PATH.

## Scheduled jobs

- [`update-flake-lock.yml`](../.github/workflows/update-flake-lock.yml)
  opens a `flake: update inputs` PR every Monday (or on demand from the
  Actions tab), so the inputs don't fall behind. It needs one of two
  repo settings, or the PR is never opened (the job fails with "GitHub
  Actions is not permitted to create or approve pull requests"):
  - a fine-grained token for this repo (Contents + Pull requests: read
    and write) as the `FLAKE_UPDATE_TOKEN` secret — preferred, since
    PRs opened with it also get CI;
  - or Settings → Actions → General → "Allow GitHub Actions to create
    and approve pull requests"; the PR then opens with the default
    token, which doesn't trigger `check.yml`, so run it on the branch
    by hand.
- [Dependabot](../.github/dependabot.yml) proposes updates for the
  GitHub Actions, which are pinned to commit SHAs (the version is in the
  trailing comment).

## The `ci` and `ci-work` hosts (`nix/hosts/ci*/`)

`ci` mirrors m5 — `profiles = [ "dev" "personal" ]` and
`../m5/dock.nix`; `ci-work` mirrors the work Mac — `[ "dev" "work" ]`
and `../work/dock.nix`. Both take the runner setup in
`nix/hosts/ci/runner.nix`:

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
- **Local machine state** — the runner tracks the real host's macOS
  major (now 27; moved off macOS 15 after a build that passed there
  failed on the Mac), but it's a fresh image: Keychain, existing
  Homebrew state and app security prompts only show up on the Mac.
- **The `work` profile's activation** — the `work` host is evaluated
  but never installed (its Claude Code setup needs DevAI and a Proton
  Pass login), so `cc-work`, the gateway hooks and the work casks only
  get exercised on the work Mac. `tests/gateway-check.sh` covers the
  hook's logic.

## Maintenance couplings

- New gateway-check behaviour or a new bypass found? Add a fixture to
  [`tests/gateway-check.sh`](../tests/gateway-check.sh) — blocking cases
  and the sessions that must stay allowed.
- The smoke check hardcodes formulas `flux pass-cli` and tools
  `kubectl helm gh`. If the `dev` brews or packages change, update the
  workflow lists.
- The smoke check's symlink list must track `nix/home/files.nix` and
  `nix/home/claude-code.nix` — add a check when adding an important
  managed file.
- The bootstrap is `setup.sh` itself, which runs `darwin-rebuild` via
  `--inputs-from`, i.e. from the nix-darwin revision in `flake.lock` —
  no separate pin to keep in sync. Steps that can't run on a runner
  must stay skippable (they already are: each installer checks first).
