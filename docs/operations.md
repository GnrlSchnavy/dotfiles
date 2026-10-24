# Operations

## The everyday loop

```bash
# 1. Edit config in ~/.dotfiles
# 2. Stage it — flakes only see git-tracked files
git add -A
# 3. Apply (system + user + homebrew in one shot; sudo is required)
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#${DOTFILES_HOST:-$(scutil --get LocalHostName)} -v
```

Other common operations:

```bash
# Newer flake inputs: master only takes PRs, so let CI bump and test them,
# merge the PR once green, then apply
gh workflow run update-flake-lock.yml
~/.dotfiles/scripts/update.sh

# Ship your own committed change (opens a PR; merge it once CI is green)
dotpr

# Roll back the last rebuild
sudo darwin-rebuild --rollback

# Evaluate every host without building/applying (~1 min cold)
cd ~/.dotfiles/nix && nix flake check --no-build

# Gateway-check, subagent, cc-tooling, settings-merge and doc-drift tests
~/.dotfiles/tests/run.sh
```

## Bootstrap a machine: `./setup.sh`

Idempotent; safe to re-run. Steps, in order:

1. Rosetta 2 (Apple Silicon) and Xcode CLT (exits and asks for a
   re-run if CLT was just triggered).
2. Clones the repo to `~/.dotfiles` (skips if present).
3. Verifies `nix/hosts/${DOTFILES_HOST:-$(scutil --get LocalHostName)}/default.nix`
   exists — if not, prints the new-host onboarding steps and exits
   (see [hosts.md](hosts.md)).
4. Installs Homebrew (nix-homebrew patches it later but needs the
   initial install) and Nix (multi-user daemon): a pinned release
   (`NIX_VERSION` in setup.sh), whose installer must match the pinned
   SHA-256 before it runs. To bump: take the version and its
   `https://releases.nixos.org/nix/nix-<version>/install.sha256`.
5. Moves pre-existing `/etc/nix/nix.conf`, `/etc/bashrc`, `/etc/zshrc`
   to `*.before-nix-darwin` so nix-darwin can take them over.
6. `sudo nix run --inputs-from ~/.dotfiles/nix nix-darwin#darwin-rebuild -- switch --flake ~/.dotfiles/nix#<host>`
   — `darwin-rebuild` comes from the nix-darwin revision locked in `flake.lock`.
7. Prints the once-per-machine sign-ins: `pass-cli login` and, on the
   work machine only, `devai setup` (then start Claude with `cc-work`).
   Nothing else is manual: the rebuild installs
   mise's Java/Node versions and creates `~/.claude/settings.json` from
   the repo snapshot, and Claude Code fetches the declared plugins on its
   first session.

`DOTFILES_DIR` and `DOTFILES_HOST` override the checkout location and
the host descriptor; CI uses them to run this script on its checkout
against the `ci` host.

## Reinstalling a Mac (factory reset)

Nix recreates the configuration; it does not recreate **data**. Before
erasing:

1. **Code:** no repo may have unpushed commits, stashes, uncommitted work
   or a missing remote. Check every repo:
   ```bash
   find ~/projects/personal -maxdepth 3 -name .git -type d -prune | sed 's|/.git$||' |
     while read -r d; do
       printf '%-40s changed:%s unpushed:%s remotes:%s\n' "${d##*/}" \
         "$(git -C "$d" status --porcelain | wc -l)" \
         "$(git -C "$d" log --branches --not --remotes --oneline | wc -l)" \
         "$(git -C "$d" remote | wc -l)"
     done
   ```
2. **Secrets not yet in Proton Pass** (files with passwords; the homelab
   kubeconfig already is, see [secrets.md](secrets.md#homelab-kubeconfig)):
   store them as notes, from stdin so they stay out of shell history:
   `jq -n --rawfile n <file> '{title: "<title>", note: $n}' | pass-cli item create note --vault-name <vault> --from-template -`.
3. **Files:** `~/Documents`, `~/Downloads`, `~/Desktop`, app data you care
   about (Alfred preferences, Claude Code memories in
   `~/.claude/projects/*/memory`, `~/.codemem/<lane>`) → NAS or Proton
   Drive. SSH keys need nothing: they live in Proton Pass ([ssh.md](ssh.md)).
4. **Ready to sign back in:** your Proton account (password and 2FA) — it's
   the root of trust for everything else — and your Apple ID.

Erase: System Settings → General → Transfer or Reset → **Erase All
Content and Settings**. In Setup Assistant, name the Mac after its host
(`m5`), or select the host later with `DOTFILES_HOST=<host> ./setup.sh`.

Afterwards:

```bash
xcode-select --install
git clone https://github.com/GnrlSchnavy/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && DOTFILES_HOST=<host> ./setup.sh
```

Then, in a new terminal: `pass-cli login`, the Keychain fix for
`pass-cli` ([ssh.md](ssh.md#prerequisites-once-per-mac)), `launchctl
kickstart -k gui/$(id -u)/org.nix-community.home.proton-pass-ssh-agent`,
the SSH checks from [ssh.md](ssh.md#applying-and-checking), and (personal)
open Alfred once, rebuild, restart Alfred for its Cmd-Space hotkey, and
the `homelab-secrets` agent's first run for the kubeconfig and the
Sealed Secrets backup (`launchctl kickstart
gui/$(id -u)/org.nix-community.home.homelab-secrets`, see
[secrets.md](secrets.md#homelab-kubeconfig)).

## Maintenance scripts (`scripts/`)

| Script | What it does | When |
|---|---|---|
| `update.sh` | `git pull --ff-only` → shows the pulled commits and asks before going on → `darwin-rebuild build` → `sudo darwin-rebuild switch` | after merging a PR (yours or the weekly lock update); it never bumps inputs itself |
| `check.sh` | Health check: repo clean, flake evaluates, host descriptor exists, every home-manager symlink resolves, tooling on PATH, mise's configured versions installed | after a rebuild or when something feels off |
| `lint.sh` | nixfmt, statix, deadnix, shellcheck and a gitleaks scan; also the pre-commit hook and a CI step | runs on every commit; by hand after a big edit (`cd nix && nix fmt` fixes formatting) |
| `backup.sh` | Copies the state git can't regenerate (Claude `settings.json` and `.claude.json`, codemem DBs, Docker config) plus brew lists and versions into `~/.dotfiles-backups/<timestamp>/`, owner-only; keeps the newest 5 | runs weekly on its own (launchd agent `dotfiles-backup`, Mondays 12:00, `nix/home/backup.nix`); by hand before a big flake update or experiment |

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
removes anything not declared in the host's profiles' `homebrew.nix`. Declare it
(see [packages.md](packages.md#-cleanup--zap)).

**"Refusing to load formula ... from untrusted tap"** — Homebrew
(mid-2026+) gates third-party taps behind explicit trust.
`nix/modules/homebrew-trust.nix` handles this declaratively: it trusts
each third-party formula and cask the host declares (`owner/tap/name`
entries), one by one, not the whole tap, and nix-homebrew writes the
entries during activation, before brew bundle. If the error still
appears, the rebuild ran before the module landed on this machine —
pull and rebuild again, or `brew trust --formula <owner/tap/name>` once
by hand. Trust outlives its entry: after removing a tap package, run
`brew untrust --formula <owner/tap/name>`; `brew trust` lists what's
trusted.

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
