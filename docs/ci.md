# CI: fresh-install test

[`.github/workflows/check.yml`](../.github/workflows/check.yml) runs
on every push/PR to `master` (plus manual dispatch). Two jobs:

1. **`checks`** (Linux, ~2 min) — `nix flake check --no-build
   --all-systems ./nix` evaluates every host and the onboarding
   template (evaluation works
   cross-platform), [`scripts/lint.sh`](../scripts/lint.sh) in the
   flake's dev shell (nixfmt, statix, deadnix, shellcheck, and
   gitleaks over the tree and every commit, since the repo is public: a
   secret added and removed within one push is still in its history),
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
3. **Move the runner's Homebrew aside** (`/opt/homebrew.runner`): it
   isn't a git checkout, so nix-homebrew couldn't adopt it.
4. **Run `./setup.sh` itself** with `DOTFILES_DIR` set to the checkout
   and `DOTFILES_HOST` set to the job's host (`ci` or `ci-work`). It
   installs Homebrew as on a new Mac, which nix-homebrew then takes
   over; Xcode CLT and Nix are already on the runner, so it skips those
   installers; it moves
   `/etc/nix/nix.conf`, `/etc/bashrc`, `/etc/zshrc` aside and applies
   the flake via `--inputs-from`. The GitHub token reaches the root
   `nix run` through `NIX_CONFIG` (setup.sh passes it through sudo),
   because the nix.conf that held it was just moved aside.
5. **Rebuild over the install**: a second `darwin-rebuild switch` with
   the installed `darwin-rebuild`, since every real rebuild runs over an
   existing install; activation steps that only break the second time
   (a non-idempotent merge, a launchd reload, nix-homebrew's adopted
   prefix) fail here.
6. **Smoke checks**: PATH is prepended with
   `/run/current-system/sw/bin` and the per-user profile, then it
   asserts:
   - the home-manager symlinks exist (`~/.zshrc`, `~/.zprofile`,
     `~/.zshenv`, `~/.config/git/{config,ignore}`, `~/.ideavimrc`);
   - Claude Code: `~/.claude/settings.json` is a regular file with
     codemem declared (the merged keys); then per role —
     - both: the secret read-denies are merged in, the sandbox is forced
       on and writes only its own caches;
     - `ci` (personal): the sandbox reaches only the git SSH agent,
       `~/.codemem/personal`
       exists, and the vault path was filled into the skills;
     - `ci-work` (work): the gateway-check hook is merged in and
       executable, `skipWebFetchPreflight` is set, `~/.codemem/work`
       exists, `cc-work` is defined, and `cc-tooling`, `m2-render`, `az`
       and `kubelogin` are on PATH;
   - the `dotfiles-backup` launchd agent is loaded, and a
     `launchctl kickstart` of it leaves a backup in `~/.dotfiles-backups`;
   - `darwin-rebuild`, `brew` and `mise` (with its config) are in
     place, macOS's `java_home` lists mise's Temurin 25 and 21, the
     tapped formulas `flux` and `pass-cli` are installed, and nixpkgs'
     `kubectl`, `helm` and `gh` are on PATH.

## Scheduled jobs

- [`update-flake-lock.yml`](../.github/workflows/update-flake-lock.yml)
  opens two PRs every Monday (or on demand: Actions → update flake.lock
  → Run workflow, or `gh workflow run update-flake-lock.yml`), so the
  inputs don't fall behind: `flake: update nix-homebrew` on its own (one
  maintainer, its activation runs as root, and a bump of it once broke
  every rebuild) and `flake: update inputs` for the rest. Read the
  nix-homebrew one before merging. Both are opened with
  `FLAKE_UPDATE_TOKEN`, a fine-grained token for this repo (Contents +
  Pull requests: read and write), so `check.yml` runs on them; the job
  fails without it, and when it expires (renew it, same secret name).
  The job's own token is read-only.
- [Dependabot](../.github/dependabot.yml) proposes updates for the
  GitHub Actions, which are pinned to commit SHAs (the version is in the
  trailing comment).

## `master` is protected

Both Macs apply `master` as root on their next update, so nothing lands
there unchecked. A repository ruleset (Settings → Rules → Rulesets),
named `master`, targets the default branch with:

- **Require a pull request before merging**, 0 approvals (a one-person
  repo): no direct pushes, not from you, a Claude session or the
  lock-update token.
- **Require status checks to pass**: `checks`, `fresh-install (ci)`,
  `fresh-install (ci-work)`. The workflow has no path filters, so every
  PR reports all three.
- **Block force pushes** and **restrict deletions**.
- No bypass list.

Your own changes go the same way: commit as usual, then `dotpr [branch]`
(a zsh function, `nix/home/zsh.nix`) moves commits made on `master` to a
branch, pushes it and opens the PR with `gh`; merge it once CI is green,
then `scripts/update.sh`. Needs `gh auth login` once per Mac.

Renaming a job or a matrix host renames its check: update the ruleset in
the same PR, or nothing can merge.

## The `ci` and `ci-work` hosts (`nix/hosts/ci*/`)

`ci` mirrors m5 — `profiles = [ "dev" "personal" ]` and
`../m5/dock.nix`; `ci-work` mirrors the work Mac — `[ "dev" "work" ]`
and `../work/dock.nix`. Both take the runner setup in
`nix/hosts/ci/runner.nix`:

- `homebrew.casks = lib.mkForce [ ]` — casks are multi-GB and a few
  have DSL incompatibilities with the runner's Homebrew; brews alone
  exercise the brew-bundle path.
- Homebrew is nix-homebrew's, cleanup `zap` included, as on the Macs:
  the job moves the runner's own Homebrew aside first.
- `homebrew.onActivation.upgrade = lib.mkForce false` — nothing to
  upgrade on a fresh runner; avoids unrelated upstream failures.
- `username = "runner"`, home `/Users/runner`.

## What CI catches / misses

Catches: Nix eval errors, package build failures, activation script
errors, home-manager activation problems, brew formula issues, and
nix-homebrew's own `brew` (its launcher with the brew it pins): the
smoke checks run it, and `tests/flake-lock.sh` fails if `brew-src` is
overridden again, the mismatch that once broke every rebuild while CI
stayed green.

Misses:

- **Cask problems** (casks are dropped in CI).
- **Local machine state** — the runner tracks the real host's macOS
  major (now 27; moved off macOS 15 after a build that passed there
  failed on the Mac), but it's a fresh image: Keychain, existing
  Homebrew state and app security prompts only show up on the Mac.
- **Anything behind a login** — `ci-work` installs the work profile, but
  DevAI and Proton Pass aren't signed in, so `cc-work`, the gateway
  check in a live session, the SSH agents and the `pass-cli` renders
  only run on the Macs. `tests/gateway-check.sh` covers the hook's
  logic.

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
