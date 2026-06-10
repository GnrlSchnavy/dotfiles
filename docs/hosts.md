# Hosts

Every machine gets a descriptor directory under `nix/hosts/<name>/`
holding its descriptor (`default.nix`) and the four per-host modules
it is allowed to diverge on: `packages.nix`, `homebrew.nix`,
`dock.nix` (nix-darwin) and `git.nix` (home-manager).

## Inventory

| Host | Machine | User | Notes |
|---|---|---|---|
| `m4` | Apple Silicon Mac (personal) | `yvan` | Original host; git identity yvanstemmerik@gmail.com; extra tooling (k8s stack, gnupg, tmux, wireguard-tools, lens, crossover, tor-browser, jellyfin) |
| `m5` | Apple Silicon Mac (work) | `yvan-sytac` | Seeded from m4 then pruned; git identity yvan.stemmerik@ah.nl; adds microsoft-outlook; smaller brew/cask set |
| `ci` | GitHub Actions `macos-15` runner | `runner` | Fresh-install test target only. Reuses `../m4/*` modules with CI overrides (casks forced to `[]`, cleanup `none`, no upgrade). Never use on a real machine |
| `template` | — | — | Copy source for onboarding; placeholders `REPLACE_ME_*` |

m4 and m5 are **expected to diverge** — don't copy lists between them
unless asked.

## Onboarding a new Mac

1. Copy the template (on any machine, then commit):
   ```bash
   cp -r nix/hosts/template nix/hosts/<hostname>   # hostname = scutil --get LocalHostName
   cp nix/hosts/m4/{homebrew,packages,dock,git}.nix nix/hosts/<hostname>/
   ```
2. Edit `nix/hosts/<hostname>/default.nix`: replace every
   `REPLACE_ME_*` (hostname, username, the `users.users.<name>.home`
   line), set `nixpkgs.hostPlatform` (`aarch64-darwin` unless Intel).
3. Prune the seeded `homebrew.nix` / `packages.nix` / `dock.nix` /
   `git.nix` for the new machine (at minimum: git identity).
4. Register in `nix/flake.nix`:
   ```nix
   hosts = {
     m4 = import ./hosts/m4;
     m5 = import ./hosts/m5;
     ci = import ./hosts/ci;
     <hostname> = import ./hosts/<hostname>;
   };
   ```
5. `git add nix/hosts/<hostname>/ nix/flake.nix && git commit` —
   **flakes only read git-tracked files**; setup fails without this.
6. On the new machine: clone and run `./setup.sh`. It detects the
   hostname, verifies the descriptor exists, installs Homebrew + Nix,
   moves conflicting `/etc` files aside, bootstraps nix-darwin, and
   seeds the non-symlinkable Claude settings.

## Descriptor gotchas

- `hostname` must exactly match `scutil --get LocalHostName`;
  `setup.sh`, `update.sh` and `check.sh` all resolve the flake target
  from it.
- `username` must match `whoami`; it feeds `system.primaryUser`,
  nix-homebrew's `user`, the home-manager user, and the nvim
  `flakePath` (`/Users/<username>/.dotfiles/nix`).
- Omitting `users.users.<name>.home` breaks the rebuild (home-manager
  type error on `home.homeDirectory`).
- `system.stateVersion = 5` and `home.stateVersion = "25.11"` are
  pinned; bump only after reading the respective release notes.
