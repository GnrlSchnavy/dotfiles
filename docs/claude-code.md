# Claude Code integration

Claude Code configuration is version-controlled in
`system/.claude/` and wired into `~/.claude/` two different ways,
depending on whether the app rewrites the file at runtime.

## Managed via home-manager symlinks (static files)

Declared in [`nix/home/files.nix`](../nix/home/files.nix); applied on
every rebuild:

- `~/.claude/settings.local.json` ← `system/.claude/settings.local.json`
  (active permission allowlist)
- `~/.claude/settings.template.json` ← `system/.claude/settings.template.json`
  (starter allowlist for new machines)
- `~/.claude/README.md` ← `system/.claude/README.md`
- `~/.claude/agents` ← `system/.claude/agents/` (custom subagents,
  whole directory, read-only)
- `~/.claude/commands` ← `system/.claude/commands/` (slash commands)
- `~/.claude/skills` ← `system/.claude/skills/` (the `vault-*`
  Obsidian skills, etc.)

To change any of these: edit the file under
`~/.dotfiles/system/.claude/`, `git add`, rebuild. Files inside the
symlinked directories are read-only at `~/.claude/` — they can only be
changed through the repo.

## Seeded reference snapshots (runtime-rewritten files)

`~/.claude/settings.json` and `~/.claude-mem/settings.json` are
rewritten by the apps at runtime (plugin toggles, effort level, etc.),
so they **must not** be Nix-store symlinks. The repo keeps reference
snapshots:

- `system/.claude/settings.json`
- `system/.claude-mem/settings.json`

`setup.sh` copies them into place **only when the destination is
absent** (so re-running setup never clobbers app-managed state), and
rewrites any absolute `/Users/<name>` paths to the current `$HOME`
during seeding (the snapshots were taken on a machine whose username
differs from other hosts').

Manual re-seed:

```bash
cp ~/.dotfiles/system/.claude/settings.json ~/.claude/settings.json
cp ~/.dotfiles/system/.claude-mem/settings.json ~/.claude-mem/settings.json
# then fix any /Users/<other-user> paths inside if seeding by hand
```

To refresh a snapshot after changing settings in the app: copy the
runtime file back into the repo and commit.

Everything else under `~/.claude/` (transcripts, session state, plugin
caches) is deliberately unmanaged.

## claude-mem: manual per-machine install

claude-mem can't be fully declared in Nix — it's an imperative
installer that writes Claude Code lifecycle hooks, runs a background
worker daemon, and builds a SQLite + Chroma store under
`~/.claude-mem/`. We declare what we can and run the installer by hand
once per machine:

- **Declared:** its runtime deps `bun` + `uv` are pinned as brews in
  `nix/hosts/<host>/homebrew.nix` (machine-scope, not behind nvm/pyenv —
  bun runs the worker daemon, uv backs the Python vector search;
  otherwise claude-mem auto-fetches unpinned copies). Its tuned config
  snapshot lives at `system/.claude-mem/settings.json`.
- **Manual:** after the first `darwin-rebuild switch` (so `bun`/`uv`
  exist), run the installer, then restore the tuned settings:

```bash
npx claude-mem install                # writes hooks, starts the worker
cp ~/.dotfiles/system/.claude-mem/settings.json ~/.claude-mem/settings.json
npx claude-mem restart                # reload worker with tuned settings
```

`setup.sh`'s seed step only copies `~/.claude-mem/settings.json` when
absent, and `npx claude-mem install` creates that file itself — so run
the installer first, then the `cp` above to overwrite it with our
snapshot. (On a host whose username differs from the snapshot's, fix
the `/Users/<name>` paths inside afterward, as setup.sh's seeder does
automatically.)

Note: `bun`/`uv` are currently pinned on m4 only. Add them to another
host's `homebrew.nix` before running the claude-mem installer there.

## Repo-level Claude config

- `CLAUDE.md` at the repo root is the agent entry point; it defers to
  `docs/` for detail.
- `.gitignore` excludes `/.claude/` at the repo root (machine-local
  Claude Code worktree state) — distinct from `system/.claude/`, which
  is versioned.
- The global git ignores (per-host `git.nix`) exclude
  `**/.claude/settings.local.json` and `**/CLAUDE.local.md` in *other*
  repos; this repo's `system/.claude/settings.local.json` is tracked
  because it's the source the symlink points to, not a local override.
