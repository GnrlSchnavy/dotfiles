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
| `m5` | Apple Silicon Mac, personal | `yvan-sytac` | `dev`, `personal` | No client work. Claude Code on Claude Max |
| `work` | Client-issued Mac (Ahold) | `changeme` (placeholder) | `dev`, `work` | Not set up yet: username and hostname are placeholders (TODO in `nix/hosts/work/default.nix`). Claude Code only through DevAI/TechNL |
| `ci` | GitHub Actions `xcode-27` (macOS 27) runner | `runner` | `dev`, `personal` | Fresh-install test target only. Mirrors m5 (its profiles and `../m5/dock.nix`) with CI overrides (casks forced to `[]`, cleanup `none`, no upgrade). Never use on a real machine |
| `template` | — | — | `dev`, `personal` | Copy source for onboarding; placeholders `REPLACE_ME_*` |

The `work` host is only evaluated in CI (`nix flake check`), not
installed: its Claude Code setup needs DevAI and a Proton Pass login.

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

The descriptor already exists; it only needs the machine's names.

1. On the work Mac, read `whoami` and decide the hostname: either
   `sudo scutil --set LocalHostName work`, or rename
   `nix/hosts/work/`, its `hostname` and the `work` entry in
   `nix/flake.nix` to the Mac's existing `LocalHostName`.
2. In `nix/hosts/work/default.nix`, replace `changeme` (three places)
   with the username. Adjust `dock.nix` if you like. Commit and push
   (from any machine — **flakes only read git-tracked files**).
3. On the work Mac: clone to `~/.dotfiles` and run `./setup.sh`.
4. Sign in, once: `pass-cli login` (Proton Pass, for the TechNL refs),
   then install the DevAI CLI and run `devai setup`
   ([docs/claude-code.md](claude-code.md#work-profile)).
5. Start Claude Code with `cc-work`. The SSH key for the work GitHub
   account goes in `~/.ssh/config` on the machine (unmanaged).

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

- `hostname` must exactly match `scutil --get LocalHostName`;
  `setup.sh`, `update.sh` and `check.sh` all resolve the flake target
  from it.
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
