# Shell & dotfiles

All user-level dotfiles are produced by home-manager on rebuild as
read-only symlinks into `/nix/store`. **Never edit `~/.zshrc`,
`~/.config/git/config`, `~/.ideavimrc`, etc. directly** — edit the
source in `~/.dotfiles/` and rebuild.

## Zsh ([`nix/home/zsh.nix`](../nix/home/zsh.nix))

| Where | Written to | Contains |
|---|---|---|
| `programs.zsh.history`, `autosuggestion`, `syntaxHighlighting`, `shellAliases` | `~/.zshrc` | 100k shared history (no dups, leading-space commands unsaved), inline suggestions, highlighting, `j` → `z` |
| `programs.fzf`, `programs.zoxide` | `~/.zshrc` | Ctrl-R fuzzy history, Ctrl-T files, Alt-C dirs; `z`/`j` directory jumping |
| `programs.zsh.profileExtra` | `~/.zprofile` (login shells) | Homebrew shellenv |
| `programs.zsh.initContent` | `~/.zshrc` (interactive shells) | kubectl completion cache, PATH additions, `notes`/`note`; `mise activate` (from [`nix/home/mise.nix`](../nix/home/mise.nix)) |
| `home.sessionPath` (mise.nix) | hm session vars (all shells) | mise shims, for non-interactive callers |
| `home.sessionVariables` (profiles) | hm session vars (all shells) | `DOCKER_HOST`, `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE` ([`nix/profiles/dev/docker.nix`](../nix/profiles/dev/docker.nix)); `OBSIDIAN_VAULT` (personal) |
| `programs.zsh.initContent` (profiles) | `~/.zshrc` | personal: the sandbox `git()` wrapper; work: `cc-work`, `cc-work-desktop` ([claude-code.md](claude-code.md)); every machine: `codemem-setup` |
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

Claude Code's files (`~/.claude/{CLAUDE.md,README.md,agents,commands}`,
plus `skills` / `hooks` per profile) are linked by
[`nix/home/claude-code.nix`](../nix/home/claude-code.nix) and the
profiles — see [claude-code.md](claude-code.md#shared-plumbing).

Adding a new dotfile: put the source somewhere sensible in the repo
(`editors/`, `system/`, …), add a `home.file."<target>".source = ...;`
entry, `git add`, rebuild.

Git config is **not** here — it's the typed `programs.git` module in
[`nix/home/git.nix`](../nix/home/git.nix): the personal identity as the
default, overridden by the work profile (`nix/profiles/work/git.nix`);
the dotfiles clones always commit as personal. It writes
`~/.config/git/config` and `~/.config/git/ignore` (XDG paths — there is
no `~/.gitconfig` / `~/.gitignore_global`).

## Files that must NOT be symlinked

Some apps rewrite their config at runtime via atomic rename. A
read-only Nix-store symlink breaks that (`cross-device link` /
read-only errors). These files are therefore **owned by the app**:

| Runtime file | Repo reference | How it gets there |
|---|---|---|
| `~/.claude/settings.json` | `system/.claude/settings.json` | created from the snapshot when absent, then the owned keys merged on every rebuild by `claude-code.nix` |
| `~/.docker/config.json` | *(none)* | never seeded — Colima writes its current context (`colima`) there at start |

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
- **macOS defaults** (keyboard, finder, animations):
  `nix/modules/system.nix`; dock behavior: `nix/modules/dock.nix` (both
  shared); `nix/hosts/<name>/dock.nix` (per-host dock apps). Dock apps must exist in `/Applications` — i.e.
  be installed as casks by one of the host's profiles — or the dock
  entry shows a question mark.
