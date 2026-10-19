# Hosts

Every machine gets a directory under `nix/hosts/<name>/` holding its
descriptor (`default.nix`) and what only that machine has: `dock.nix`.
Everything a machine shares with others of its **role** — apps,
packages, git identity, Claude Code — comes from the profiles the
descriptor lists (see [nix/profiles/README.md](../nix/profiles/README.md)):
`dev` plus exactly one of `personal` / `work`.

## Inventory

| Host | Machine | User | Profiles | Notes |
|---|---|---|---|---|
| `m5` | Apple Silicon Mac, personal | `yvan` | `dev`, `personal` | No client work. Claude Code on Claude Max |
| `work` | Client-issued Mac (Ahold), managed by the client's device management | `pnl1ln25` | `dev`, `work` | Its LocalHostName is a client asset tag, so it's selected with `DOTFILES_HOST=work` (see below). Claude Code only through DevAI/TechNL |
| `ci` | GitHub Actions `xcode-27` (macOS 27) runner | `runner` | `dev`, `personal` | Fresh-install test target only. Mirrors m5 (its profiles and `../m5/dock.nix`) with CI overrides (casks forced to `[]`, cleanup `none`, no upgrade). Never use on a real machine |
| `template` | — | — | `dev`, `personal` | Copy source for onboarding; placeholders `REPLACE_ME_*` |

CI only evaluates the `work` host (`nix flake check`); it never installs
it, since its Claude Code setup needs DevAI and a Proton Pass login.

### Decommissioned

`m4` (Apple Silicon Mac, personal, user `yvan`) was the original host.
The machine was sold in **August 2026** and its descriptor removed.
Its per-host modules are recoverable from git history:

```bash
git show 8594049:nix/hosts/m4/homebrew.nix
```

Until October 2026 m5 also served as the work machine, running a
personal and a work Claude Code setup side by side; client work moved
to the client-issued Mac.

## The dotfiles clones

[`nix/home/git.nix`](../nix/home/git.nix) assumes this repo may be
cloned twice: `~/projects/personal/dotfiles` to edit and `~/.dotfiles`
to rebuild from. Both always commit with the personal git identity and
GitHub login and run the repo's `.githooks/`, on every machine (the work
profile's identity applies everywhere else). A change made in the
editing clone reaches the machine after commit, push, `git pull` in
`~/.dotfiles` and a rebuild; to try it before pushing, rebuild straight
from the editing clone
(`sudo darwin-rebuild switch --flake ~/projects/personal/dotfiles/nix#m5`).
With a single clone, keep it at `~/.dotfiles`.

## Onboarding the work Mac

The descriptor is filled in (`nix/hosts/work/default.nix`). The Mac's
hostname is set by the client's device management, so don't rename it:
the flake host stays `work` and is selected with `DOTFILES_HOST`.

1. Check whether Zscaler inspects TLS ([Zscaler](#zscaler-on-the-work-mac)).
2. `xcode-select --install`, then:
   ```bash
   git clone https://github.com/GnrlSchnavy/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles && DOTFILES_HOST=work ./setup.sh
   ```
   After the first rebuild the flake sets `DOTFILES_HOST=work` in every
   shell, so later rebuilds (`update.sh`, the usual command) find it.
3. Sign in, once: `pass-cli login` (Proton Pass: the TechNL refs and the
   SSH keys), the Keychain fix for `pass-cli`
   ([docs/ssh.md](ssh.md#prerequisites-once-per-mac)), then install the
   DevAI CLI and run `devai setup`
   ([docs/claude-code.md](claude-code.md#work-profile)).
4. Check SSH (`ssh -T git@github.com`, `ssh -T git@github-personal`) and
   start Claude Code with `cc-work`.

### Zscaler on the work Mac

Zscaler may intercept HTTPS and re-sign it with the client's root
certificate. macOS apps trust it (device management installs it), but
Nix, nixpkgs' git and curl, Node and the JDKs carry their own CA bundles
and would reject it. Check before installing:

```bash
for h in cache.nixos.org github.com repo.maven.apache.org registry.npmjs.org; do
  printf '%s: ' "$h"
  openssl s_client -connect "$h:443" -servername "$h" </dev/null 2>/dev/null |
    openssl x509 -noout -issuer
done
```

An issuer naming Zscaler means that host is intercepted.

## Onboarding a new Mac

1. Copy the template (on any machine, then commit):
   ```bash
   cp -r nix/hosts/template nix/hosts/<hostname>   # hostname = scutil --get LocalHostName
   cp nix/hosts/m5/dock.nix nix/hosts/<hostname>/
   ```
2. Edit `nix/hosts/<hostname>/default.nix`: replace every
   `REPLACE_ME_*` (hostname, username, the `users.users.<name>.home`
   line), pick the `profiles`, set `nixpkgs.hostPlatform`
   (`aarch64-darwin` unless Intel). Prune `dock.nix`.
3. Register in `nix/flake.nix`:
   ```nix
   hosts = {
     m5 = import ./hosts/m5;
     work = import ./hosts/work;
     ci = import ./hosts/ci;
     <hostname> = import ./hosts/<hostname>;
   };
   ```
4. `git add nix/hosts/<hostname>/ nix/flake.nix && git commit` —
   **flakes only read git-tracked files**; setup fails without this.
5. On the new machine: clone and run `./setup.sh`. It detects the
   hostname, verifies the descriptor exists, installs Homebrew + Nix,
   moves conflicting `/etc` files aside and bootstraps nix-darwin, which
   also creates `~/.claude/settings.json` from the repo snapshot.

## Descriptor gotchas

- `hostname` is the flake host name. `setup.sh`, `update.sh`,
  `check.sh` and the rebuild command use `$DOTFILES_HOST` when set (the
  flake sets it on every machine after the first rebuild), else
  `scutil --get LocalHostName` — so name a new host after its
  LocalHostName, or install it with `DOTFILES_HOST=<host> ./setup.sh`.
- `username` must match `whoami`; it feeds `system.primaryUser`,
  nix-homebrew's `user`, the home-manager user, and the nvim
  `flakePath` (`/Users/<username>/.dotfiles/nix`).
- Omitting `users.users.<name>.home` breaks the rebuild (home-manager
  type error on `home.homeDirectory`).
- `personal` and `work` set the same options (codemem lane, git
  identity) and must never share a machine; listing both fails
  evaluation on the conflicting codemem lane.
- `system.stateVersion = 5` and `home.stateVersion = "25.11"` are
  pinned; bump only after reading the respective release notes.
