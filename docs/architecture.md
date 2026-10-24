# Architecture

A reproducible macOS environment built from one flake at
[`nix/flake.nix`](../nix/flake.nix). One command applies everything:

```bash
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#<host> -v
```

## The three layers

| Layer | Manages | Config lives in |
|---|---|---|
| **nix-darwin** | System: macOS defaults, dock, keyboard, launchd, system packages | `nix/modules/*.nix` (shared, Dock behaviour included) + `nix/profiles/<role>/{packages,homebrew}.nix` (per role) + `nix/hosts/<name>/dock.nix` (per machine: the Dock's apps) |
| **home-manager** | User: `~/.zshrc`, `~/.config/git/*`, `~/.ideavimrc`, `~/.claude/*`, Colima, Claude Code launchers | `nix/home/*.nix` (shared) + `nix/profiles/<role>/*.nix` (per role) |
| **nix-homebrew** | Homebrew itself + declared brews/casks/masApps | `nix/modules/homebrew.nix` (activation) + `nix/profiles/<role>/homebrew.nix` (lists) |

home-manager runs as a nix-darwin module, so a single
`darwin-rebuild switch` activates all three layers. All managed
dotfiles are symlinks into `/nix/store`, recreated on every rebuild.
There is no Stow and no manual symlinking.

## Flake wiring (`nix/flake.nix`)

Inputs: `nixpkgs` (`nixpkgs-26.05-darwin`, the branch Hydra tests and
caches for macOS), `nix-darwin` (`nix-darwin-26.05`), `home-manager`
(`release-26.05`), `nix-homebrew`, and `nixvim` (`nixos-26.05`). Move
them to the next release together, and leave `system.stateVersion` /
`home.stateVersion` alone unless the release notes say otherwise.

**nixvim is an input of this flake, not a separate flake** — there is
no `flake.nix` under `nix/nixvim/`, only a config module at
`nix/nixvim/config/`.

The `outputs` section defines:

- `sharedModules` — nix-darwin modules applied to every host:
  [`modules/nix.nix`](../nix/modules/nix.nix) (daemon settings, gc,
  store optimise, allowUnfree),
  [`modules/system.nix`](../nix/modules/system.nix) (macOS defaults,
  keyboard remap),
  [`modules/environment.nix`](../nix/modules/environment.nix)
  (EDITOR/VISUAL, kubectl aliases),
  [`modules/homebrew.nix`](../nix/modules/homebrew.nix) (Homebrew on,
  `cleanup = "zap"`, auto-update/upgrade), and
  [`modules/homebrew-trust.nix`](../nix/modules/homebrew-trust.nix)
  (trust for each third-party formula and cask the host declares,
  imported with nix-homebrew).
- `hostModules kind host` — a host's `systemModules` or `homeModules`:
  each listed profile's (`nix/profiles/<name>/default.nix`) first, then
  the host's own.
- `mkNvim pkgs host` — builds a per-host Neovim from
  `nix/nixvim/config/`, injecting `flakePath`
  (`/Users/<username>/.dotfiles/nix`) and `darwinHost` (the hostname)
  as `extraSpecialArgs`. These parameterize the `nixd` LSP so it can
  evaluate this flake's own options without hardcoded paths.
- `mkDarwin host` — turns a host descriptor into a
  `darwinConfiguration`: shared modules + `hostModules "systemModules"` +
  the host's inline `module` + the nvim package + nix-homebrew setup +
  home-manager (which imports `nix/home/` plus
  `hostModules "homeModules"`).
- `hosts` — every folder in `nix/hosts/` except `template` (today `m5`,
  `work`, `ci`, `ci-work`), so adding a host is adding its folder (see
  [hosts.md](hosts.md)); a descriptor's `hostname` must match its folder.
- `checks` — every host's system, grouped by platform, plus the
  onboarding `template` (with m5's dock standing in for the one you'd
  copy). `nix flake check` ignores `darwinConfigurations` on its own, so
  this output is what makes `nix flake check --no-build` actually
  evaluate the hosts.
- `formatter` (`cd nix && nix fmt`, nixfmt over every `.nix` file) and
  `devShells.default` (`nix develop ./nix`: nixfmt, statix, deadnix,
  shellcheck, gitleaks, jq — what `scripts/lint.sh` needs), for the Mac
  and for Linux CI. statix's config is `nix/statix.toml`. The tool list
  lives in `nix/lint-tools.nix`, shared with the personal profile's
  Claude Code, whose Bash sandbox can't run `nix develop`.

Home-manager is configured with `useGlobalPkgs`, `useUserPackages`, and
`backupFileExtension = "hm-backup"` — pre-existing files that would
block activation get renamed (e.g. `~/.zshrc.hm-backup`) instead of
failing.

## Host descriptor contract

Each `nix/hosts/<name>/default.nix` evaluates to a plain attrset:

```nix
{
  hostname = "...";        # flake host; = LocalHostName unless set via DOTFILES_HOST
  username = "...";        # must match `whoami` on that machine
  profiles = [ "dev" "personal" ]; # roles: "dev" + one of personal/work (optional, default [])
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

## Profiles

A profile is the config for one **role** a machine plays —
[`nix/profiles/README.md`](../nix/profiles/README.md). Its
`default.nix` returns `systemModules` / `homeModules` lists, like a host
descriptor; the flake adds them ahead of the host's own.

| Profile | Used by | Adds |
|---|---|---|
| `dev` | every host | dev casks/brews, nixpkgs CLI basics, the Colima Docker engine |
| `personal` | `m5`, `ci` | personal apps; SSH keys from Proton Pass (`SSH-git`, `SSH-personal`); Claude Code on Max, sandboxed, pushing through the git-only agent; vault skills; codemem lane `personal` |
| `work` | `work` | work apps; work git identity; Claude Code via DevAI only (`cc-work`), gateway check, Ahold overlay; codemem lane `work`; `cc-tooling` |

A host takes `dev` plus **exactly one** of `personal` / `work`: they set
the same options (codemem's lane, git identity), and client content must
never reach the personal Max login. Shared modules declare the options
(`dotfiles.claude.*` in `nix/home/claude-code.nix`,
`dotfiles.codemem.*` in `nix/home/codemem.nix`); profiles only set them.

## Directory map

`tests/docs.sh` fails when this map and `nix/` disagree.

```
nix/
├── flake.nix              # inputs + hostModules/mkDarwin/mkNvim + hosts attrset
├── flake.lock             # pinned input versions
├── lint-tools.nix         # scripts/lint.sh's tools (dev shell + personal Claude sandbox)
├── statix.toml            # statix lint config
├── profiles/              # one per role; see profiles/README.md
│   ├── README.md
│   ├── dev/               # every machine
│   │   ├── default.nix    # module lists
│   │   ├── homebrew.nix   # dev casks (IDEs, browsers, Claude, Wispr Flow); brews flux, pass-cli, opencode, openspec
│   │   ├── packages.nix   # nixpkgs CLI tools (git, jq, kubectl, helm, gh, …)
│   │   ├── docker.nix     # Colima default profile, DOCKER_HOST, docker CLI
│   │   └── alfred.nix     # Cmd-Space: Spotlight's shortcut off, Alfred's hotkey on
│   ├── personal/          # m5
│   │   ├── default.nix
│   │   ├── homebrew.nix   # personal apps (Proton, Signal, Slack, Steam, …)
│   │   ├── packages.nix   # ansible, nmap, stripe-cli, feishin (pinned dmg)
│   │   ├── firewall.nix   # application firewall + stealth mode
│   │   ├── claude.nix     # Claude Max: sandbox, plugins, DOTFILES_LINT_PATH, codemem lane
│   │   ├── ssh.nix        # SSH vaults SSH-git (GitHub, GitLab) and SSH-personal (homelab); keys in ssh/*.pub
│   │   ├── sandbox-git.nix # git push from the Bash sandbox via the git-only agent
│   │   ├── kube.nix       # homelab: kube-render, sealed-secrets-backup/-keys; daily launchd agent
│   │   ├── ansible.nix    # Ansible vault password from Proton Pass (ANSIBLE_VAULT_PASSWORD_FILE)
│   │   ├── hass.nix       # `hass`: hass-cli with the Home Assistant url/token from Proton Pass
│   │   └── vault.nix      # Obsidian vault skills, OBSIDIAN_VAULT
│   └── work/              # the client-issued Mac
│       ├── default.nix
│       ├── homebrew.nix   # Slack, GitHub Copilot, Signal, WhatsApp, Tailscale (Microsoft apps come preinstalled)
│       ├── packages.nix   # azure-cli, kubelogin (KaaS/AKS cluster access)
│       ├── git.nix        # work git identity (default on that machine)
│       ├── ssh.nix        # SSH vault SSH-work: github.com (work), github-personal (keys in ssh/*.pub)
│       ├── maven.nix      # m2-render: ~/.m2/settings.xml from a client-vault note; login + daily agent
│       └── claude.nix     # cc-work/cc-work-desktop, gateway check, overlay, model aliases, codemem lane, cc-tooling
├── hosts/
│   ├── m5/                # default.nix (profiles dev + personal) + dock.nix
│   ├── work/              # default.nix (profiles dev + work; DOTFILES_HOST=work) + dock.nix
│   ├── ci/                # GitHub Actions runner; m5's profiles and dock; runner.nix = CI overrides
│   ├── ci-work/           # GitHub Actions runner; the work Mac's profiles and dock; ../ci/runner.nix
│   └── template/          # copy to onboard a new Mac
├── modules/               # shared nix-darwin modules (every host)
│   ├── README.md
│   ├── nix.nix            # nix daemon, gc (weekly, >30d), store optimise, allowUnfree
│   ├── system.nix         # macOS defaults, caps-lock→escape, dark mode, finder
│   ├── dock.nix           # Dock behaviour (hosts' dock.nix list the apps)
│   ├── environment.nix    # EDITOR/VISUAL=nvim, kubectl aliases (k, kgp, kaf, …)
│   ├── homebrew.nix       # homebrew.enable + onActivation (cleanup = "zap")
│   └── homebrew-trust.nix # trust for the host's third-party formulae and casks
├── home/                  # shared home-manager modules (every host)
│   ├── default.nix        # imports the modules below; home.stateVersion
│   ├── zsh.nix            # .zprofile/.zshrc content, aliases, session vars
│   ├── mise.nix           # Java/Node via mise: global versions, shell hook
│   ├── git.nix            # programs.git; personal identity as mkDefault; dotfiles clones
│   ├── files.nix          # file-pointer dotfiles (.ideavimrc)
│   ├── secrets.nix        # pass-get / pass-render / pass-check (Proton Pass)
│   ├── ssh.nix            # dotfiles.ssh.{vault,gitVault,hosts}; Proton Pass SSH agents, ~/.ssh/config
│   ├── claude-code.nix    # dotfiles.claude.{settings,instructions}; settings merge; agents/commands links
│   ├── codemem.nix        # dotfiles.codemem.{lane,observer}; observer config, lane dir, plugin
│   └── backup.nix         # launchd agent: scripts/backup.sh weekly (Mondays 12:00)
└── nixvim/config/         # Neovim module (NOT a flake), built per host by mkNvim
    ├── default.nix        # entry: imports the rest, Catppuccin
    ├── lsp.nix            # language servers; nixd uses flakePath/darwinHost
    └── options.nix keymaps.nix editing.nix ui.nix neo-tree.nix completion.nix
        telescope.nix treesitter.nix markdown.nix
```

Repo root also holds the symlink *sources*: `editors/.ideavimrc`,
`system/.claude/` (settings snapshot, global `CLAUDE.md`, agents,
commands, skills), `system/claude-work/` (work hooks + Ahold overlay),
and `system/bin/` (settings merge, `claude-git-ssh`, `cc-tooling`).

## Shared vs profile vs host: the decision rule

- Same on every machine by design: **shared** — `nix/modules/`
  (system-level) or `nix/home/` (user-level). Examples: macOS
  defaults, zsh setup, Claude Code plumbing.
- Same for every machine of one role: **profile** —
  `nix/profiles/<role>/`. Examples: casks, package lists, git identity,
  Claude Code backend.
- Only this machine: **host** — `nix/hosts/<name>/`. Examples: dock,
  hostname, username.

## Neovim (NixVim)

Configured in [`nix/nixvim/config/default.nix`](../nix/nixvim/config/default.nix):
Catppuccin theme, space leader, LSP (jdtls, kotlin, nixd, ts_ls,
pyright, rust_analyzer, jsonls, yamlls, marksman, dockerls, bashls),
nvim-cmp + luasnip, Telescope (+fzf-native, file-browser), neo-tree,
Treesitter (+context, +textobjects), bufferline/lualine.

To check it evaluates without doing a full rebuild:

```bash
cd ~/.dotfiles/nix && nix flake check --no-build
# or evaluate one host: nix eval .#darwinConfigurations.m5.system.drvPath
# or build without switching: darwin-rebuild build --flake .#m5
```

(The old `nix flake check ~/.dotfiles/nix/nixvim` no longer works —
nixvim stopped being a standalone flake when the per-host `mkNvim`
build was introduced.)
