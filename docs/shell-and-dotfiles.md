# Shell & dotfiles

All user-level dotfiles are produced by home-manager on rebuild as
read-only symlinks into `/nix/store`. **Never edit `~/.zshrc`,
`~/.config/git/config`, `~/.ideavimrc`, etc. directly** — edit the
source in `~/.dotfiles/` and rebuild.

## Zsh ([`nix/home/zsh.nix`](../nix/home/zsh.nix))

| Where | Written to | Contains |
|---|---|---|
| `programs.zsh.profileExtra` | `~/.zprofile` (login shells) | Homebrew shellenv, autojump, NVM sourcing |
| `programs.zsh.initContent` | `~/.zshrc` (interactive shells) | jenv lazy-load, JAVA_HOME, kubectl completion cache, bun, PATH additions |
| `home.sessionVariables` | hm session vars (all shells) | `BUN_INSTALL`, `NVM_DIR` |
| `environment.shellAliases` (in [`nix/modules/environment.nix`](../nix/modules/environment.nix)) | `/etc/zshrc` (system-wide) | kubectl shortcuts: `k`, `kg`, `kgp`, `kgd`, `kgs`, `kga`, `kd`, `kaf`, `kdf` |

Notable mechanics:

- **jenv is lazy-loaded**: `jenv`/`java`/`javac` are shell functions
  that initialize jenv on first call, keeping shell startup fast.
- **JAVA_HOME is set eagerly** at shell startup so `./mvnw` forks the
  right JDK before jenv initializes. It reads `.java-version` from the
  *current directory* (useful when a terminal opens inside a project),
  falling back to `~/.jenv/version`, then the literal `24`. If you
  change global JDK major versions, check this fallback.
- **kubectl completion is cached** in `~/.zsh_kubectl_completion`,
  regenerated when older than 24h.
- **pyenv was removed** (June 2026). There is deliberately no
  pyenv/python wiring in zsh.nix — don't reintroduce it.

## File-pointer dotfiles ([`nix/home/files.nix`](../nix/home/files.nix))

For configs with no typed home-manager module, `home.file` symlinks
repo files into `$HOME`:

| Symlink | Source in repo |
|---|---|
| `~/.ideavimrc` | `editors/.ideavimrc` |
| `~/.claude/settings.local.json` | `system/.claude/settings.local.json` |
| `~/.claude/settings.template.json` | `system/.claude/settings.template.json` |
| `~/.claude/README.md` | `system/.claude/README.md` |
| `~/.claude/agents` (whole dir) | `system/.claude/agents/` |
| `~/.claude/commands` (whole dir) | `system/.claude/commands/` |
| `~/.claude/skills` (whole dir) | `system/.claude/skills/` |

Adding a new dotfile: put the source somewhere sensible in the repo
(`editors/`, `system/`, …), add a `home.file."<target>".source = ...;`
entry, `git add`, rebuild.

Git config is **not** here — it's the typed `programs.git` module,
per-host in `nix/hosts/<name>/git.nix` (different identity per
machine). It writes `~/.config/git/config` and `~/.config/git/ignore`
(XDG paths — there is no `~/.gitconfig` / `~/.gitignore_global`).

## Files that must NOT be symlinked

Some apps rewrite their config at runtime via atomic rename. A
read-only Nix-store symlink breaks that (`cross-device link` /
read-only errors). These files are therefore **owned by the app**, with
a reference snapshot kept in the repo:

| Runtime file | Repo reference | How it gets there |
|---|---|---|
| `~/.claude/settings.json` | `system/.claude/settings.json` | seeded by `setup.sh` only when absent |
| `~/.claude-mem/settings.json` | `system/.claude-mem/settings.json` | seeded by `setup.sh` only when absent; absolute `/Users/<name>` paths are rewritten to the current `$HOME` during seeding |
| `~/.docker/config.json` | `development/.docker/config.json` | never seeded — Docker Desktop owns it entirely |

Before adding any new symlink to `files.nix`, ask: *does the app ever
write this file itself?* If yes, use the reference-snapshot + seed
pattern instead.

## Editor configs

- **Neovim**: built per-host from `nix/nixvim/config/` — see
  [architecture.md](architecture.md#neovim-nixvim).
- **IdeaVim**: `editors/.ideavimrc` → `~/.ideavimrc`.
- **macOS defaults** (keyboard, dock behavior, finder, animations):
  `nix/modules/system.nix` (shared) and `nix/hosts/<name>/dock.nix`
  (per-host dock apps). Dock apps must exist in `/Applications` — i.e.
  be installed as casks — or the dock entry shows a question mark.
