# Architecture

A reproducible macOS environment built from one flake at
[`nix/flake.nix`](../nix/flake.nix). One command applies everything:

```bash
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#<host> -v
```

## The three layers

| Layer | Manages | Config lives in |
|---|---|---|
| **nix-darwin** | System: macOS defaults, dock, keyboard, launchd, system packages | `nix/modules/*.nix` (shared) + `nix/hosts/<name>/{packages,homebrew,dock}.nix` (per-host) |
| **home-manager** | User: `~/.zshrc`, `~/.config/git/*`, `~/.ideavimrc`, `~/.claude/*` symlinks | `nix/home/*.nix` (shared) + `nix/hosts/<name>/git.nix` (per-host) |
| **nix-homebrew** | Homebrew itself + declared brews/casks/masApps | `nix/hosts/<name>/homebrew.nix` |

home-manager runs as a nix-darwin module, so a single
`darwin-rebuild switch` activates all three layers. All managed
dotfiles are symlinks into `/nix/store`, recreated on every rebuild.
There is no Stow and no manual symlinking.

## Flake wiring (`nix/flake.nix`)

Inputs: `nixpkgs` (nixos-25.11), `nix-darwin` (release matched to
nixpkgs), `home-manager` (release-25.11), `nix-homebrew`, and `nixvim`
(nixos-25.11). **nixvim is an input of this flake, not a separate
flake** — there is no `flake.nix` under `nix/nixvim/`, only a config
module at `nix/nixvim/config/`.

The `outputs` section defines:

- `sharedModules` — nix-darwin modules applied to every host:
  [`modules/nix.nix`](../nix/modules/nix.nix) (daemon settings, gc,
  store optimise, allowUnfree),
  [`modules/system.nix`](../nix/modules/system.nix) (macOS defaults,
  keyboard remap), and
  [`modules/environment.nix`](../nix/modules/environment.nix)
  (EDITOR/VISUAL, kubectl aliases).
- `mkNvim pkgs host` — builds a per-host Neovim from
  `nix/nixvim/config/`, injecting `flakePath`
  (`/Users/<username>/.dotfiles/nix`) and `darwinHost` (the hostname)
  as `extraSpecialArgs`. These parameterize the `nixd` LSP so it can
  evaluate this flake's own options without hardcoded paths.
- `mkDarwin host` — turns a host descriptor into a
  `darwinConfiguration`: shared modules + the host's `systemModules` +
  the host's inline `module` + the nvim package + nix-homebrew setup +
  home-manager (which imports `nix/home/` plus the host's
  `homeModules`).
- `hosts` attrset — registers `m4`, `m5`, and `ci`. Adding a host means
  adding an entry here (see [hosts.md](hosts.md)).

Home-manager is configured with `useGlobalPkgs`, `useUserPackages`, and
`backupFileExtension = "hm-backup"` — pre-existing files that would
block activation get renamed (e.g. `~/.zshrc.hm-backup`) instead of
failing.

## Host descriptor contract

Each `nix/hosts/<name>/default.nix` evaluates to a plain attrset:

```nix
{
  hostname = "...";        # must match `scutil --get LocalHostName`
  username = "...";        # must match `whoami` on that machine
  systemModules = [ ... ]; # per-host nix-darwin modules (optional, default [])
  homeModules = [ ... ];   # per-host home-manager modules (optional, default [])
  module = { ... }: {      # inline nix-darwin module, must set:
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.stateVersion = 5;
    system.primaryUser = "<username>";
    users.users.<username>.home = "/Users/<username>";
  };
}
```

`users.users.<name>.home` is **required**: home-manager derives
`home.homeDirectory` from it; omitting it fails the rebuild with a
"not of type absolute path" error.

## Directory map

```
nix/
├── flake.nix            # inputs + mkDarwin/mkNvim + hosts attrset
├── flake.lock           # pinned input versions
├── hosts/
│   ├── m4/              # descriptor + homebrew/packages/dock/git modules
│   ├── m5/              # same shape, independent content
│   ├── ci/              # GitHub Actions runner; reuses ../m4/* modules with CI overrides
│   └── template/        # copy to onboard a new Mac
├── modules/             # shared nix-darwin modules (every host)
│   ├── nix.nix          # nix daemon, gc (weekly, >30d), store optimise, allowUnfree
│   ├── system.nix       # macOS defaults, caps-lock→escape, dark mode, finder
│   └── environment.nix  # EDITOR/VISUAL=nvim, kubectl aliases (k, kgp, kaf, …)
├── home/                # shared home-manager modules (every host)
│   ├── default.nix      # imports files.nix + zsh.nix + codemem.nix; home.stateVersion
│   ├── zsh.nix          # .zprofile/.zshrc content, aliases, session vars
│   ├── files.nix        # file-pointer dotfiles (.ideavimrc, .claude/*)
│   └── codemem.nix      # OpenCode config + two-lane codemem memory (oc-personal/oc-work)
└── nixvim/config/       # Neovim module (NOT a flake) — LSP, Telescope, Treesitter
```

Repo root also holds the symlink *sources*: `editors/.ideavimrc`,
`system/.claude/`, `system/.claude-mem/`, and the unmanaged Docker
reference `development/.docker/config.json`.

## Shared vs per-host: the decision rule

- Differs between machines (or plausibly will): **per-host** —
  `nix/hosts/<name>/`. Examples: package lists, casks, dock apps, git
  identity.
- Identical on every machine by design: **shared** — `nix/modules/`
  (system-level) or `nix/home/` (user-level). Examples: macOS
  defaults, zsh setup, Claude config symlinks.

m5 was seeded as a copy of m4 and then pruned independently; the two
hosts are expected to diverge. Never "sync" them without being asked.

## Neovim (NixVim)

Configured in [`nix/nixvim/config/default.nix`](../nix/nixvim/config/default.nix):
Catppuccin theme, space leader, LSP (jdtls, kotlin, nixd, ts_ls,
pyright, rust_analyzer, jsonls, yamlls, marksman, dockerls, bashls),
nvim-cmp + luasnip, Telescope (+fzf-native, file-browser), neo-tree,
Treesitter (+context, +textobjects), bufferline/lualine.

To check it builds without doing a full rebuild:

```bash
cd ~/.dotfiles/nix && nix flake check --no-build
# or evaluate one host: nix eval .#darwinConfigurations.m5.system.drvPath
```

(The old `nix flake check ~/.dotfiles/nix/nixvim` no longer works —
nixvim stopped being a standalone flake when the per-host `mkNvim`
build was introduced.)
