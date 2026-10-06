# Shell & dotfiles

All user-level dotfiles are produced by home-manager on rebuild as
read-only symlinks into `/nix/store`. **Never edit `~/.zshrc`,
`~/.config/git/config`, `~/.ideavimrc`, etc. directly** — edit the
source in `~/.dotfiles/` and rebuild.

## Zsh ([`nix/home/zsh.nix`](../nix/home/zsh.nix))

| Where | Written to | Contains |
|---|---|---|
| `programs.zsh.profileExtra` | `~/.zprofile` (login shells) | Homebrew shellenv, autojump |
| `programs.zsh.initContent` | `~/.zshrc` (interactive shells) | kubectl completion cache, PATH additions, `notes`/`note`; `mise activate` (from [`nix/home/mise.nix`](../nix/home/mise.nix)) |
| `home.sessionPath` (mise.nix) | hm session vars (all shells) | mise shims, for non-interactive callers |
| `environment.shellAliases` (in [`nix/modules/environment.nix`](../nix/modules/environment.nix)) | `/etc/zshrc` (system-wide) | kubectl shortcuts: `k`, `kg`, `kgp`, `kgd`, `kgs`, `kga`, `kd`, `kaf`, `kdf` |

Notable mechanics:

- **Java and Node come from mise**: `mise activate` switches `java`,
  `node` and `JAVA_HOME` whenever you `cd` into a project with a
  `.java-version`, `.nvmrc` or `mise.toml`, so `./mvnw` always gets the
  project's JDK. Non-interactive shells use mise's shims instead. See
  [packages.md](packages.md#language-runtimes-are-not-nix-managed).
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
| `~/.claude/settings.json` | `system/.claude/settings.json` | created from the snapshot when absent, then lane-owned keys merged on every rebuild by `claude-lanes.nix` |
| `~/.claude-work/settings.json` | *(none)* | created and merged on every rebuild by `claude-lanes.nix` (owned keys only) |
| `~/.docker/config.json` | `development/.docker/config.json` | never seeded — Docker Desktop owns it entirely |

Before adding any new symlink to `files.nix`, ask: *does the app ever
write this file itself?* If yes, use the reference-snapshot + seed
pattern instead.

## Editor configs

- **Neovim**: built per-host from `nix/nixvim/config/` — see
  [architecture.md](architecture.md#neovim-nixvim).
- **IdeaVim**: `editors/.ideavimrc` → `~/.ideavimrc`. Space is the
  leader and the leader keys mirror NixVim's (`<leader>ff` find file,
  `<leader>fg` find in files, `gd`/`gr`/`gi`, `<leader>rn`, `[d`/`]d`, …),
  each mapped to the IntelliJ action that does the same job. Uses the
  bundled surround, commentary and highlightedyank extensions; reload
  with `:source ~/.ideavimrc` or restart the IDE after a rebuild.
- **macOS defaults** (keyboard, dock behavior, finder, animations):
  `nix/modules/system.nix` (shared) and `nix/hosts/<name>/dock.nix`
  (per-host dock apps). Dock apps must exist in `/Applications` — i.e.
  be installed as casks — or the dock entry shows a question mark.
