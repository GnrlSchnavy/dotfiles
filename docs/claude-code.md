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

## OpenCode & two-lane codemem memory

Separate from Claude Code, [OpenCode](https://opencode.ai) is wired up
in [`nix/home/codemem.nix`](../nix/home/codemem.nix) (a shared
home-manager module, applied on every host) together with
[codemem](https://www.npmjs.com/package/codemem), which gives OpenCode
persistent memory.

It runs in **two isolated lanes** so client (Ahold) content is never
extracted via Anthropic directly — only through the sanctioned TechNL
proxy:

| Launcher | Provider | codemem DB | Observer extraction | Viewer port |
|---|---|---|---|---|
| `oc-personal` | Max via the `opencode-with-claude` proxy (`127.0.0.1:3456`) | `~/.codemem/personal/` | local Claude (Max) | 4747 |
| `oc-work` | TechNL proxy (URL via pass-cli), project `ahold` | `~/.codemem/work-ahold/` | TechNL proxy | 4848 |

Both lanes use `claude-sonnet-4-6` for coding and `claude-haiku-4-5`
as the codemem observer model.

How isolation holds: the two lanes have **separate DB folders** (the
viewer lock is keyed on the DB directory), **separate observer
configs**, and **separate viewer ports** — all set per-lane by the
`oc-*` shell functions. The OpenCode plugin forwards
`CODEMEM_DB` / `CODEMEM_CONFIG` / `CODEMEM_VIEWER_PORT` into the viewer
it auto-starts, and the extraction sweeper runs inside that per-lane
viewer, so work extraction provably stays in the TechNL channel.

Config layout:

- `~/.config/opencode/opencode.json` — personal config (managed via
  `xdg.configFile`)
- `~/projects/ahold/opencode.json` — work config (lives outside
  `~/.config`, so `home.file`)
- `~/.config/codemem/{personal,work-ahold}.json` — per-lane observer
  configs

Run `oc-personal` / `oc-work` (zsh functions) instead of `opencode`
directly, so each lane's env (DB, config, viewer port, provider key) is
set.

**No secrets live in the repo.** The TechNL key *and* the proxy URL are
resolved at runtime by `oc-work` via `pass-cli` (Proton Pass) — `oc-work`
**fails closed** if it can't fetch either — and paths use
`config.home.homeDirectory` so the same module works on both `m4`
(`/Users/yvan`) and `m5` (`/Users/yvan-sytac`).

Prereqs on a host: `pass-cli` (Proton Pass CLI) and `uv` must be
declared in that host's `homebrew.nix` for `oc-work` to resolve its key
and for codemem's vector search.

For **per-client custom agents and repo-specific rules** (kept out of
these public dotfiles, in a private per-client repo), see
[OpenCode client tooling](opencode-client-tooling.md).

## OpenCode instructions & agents

Source lives in `system/opencode/`; deployed by
[`nix/home/opencode.nix`](../nix/home/opencode.nix) as read-only symlinks
into `~/.config/opencode/`. These are the *global* OpenCode layer — read
by every session, both lanes.

| Deployed path | Source | Scope |
|---|---|---|
| `~/.config/opencode/AGENTS.md` | `system/opencode/AGENTS.md` | baseline rules, every session |
| `~/.config/opencode/agent/*.md` | `system/opencode/agent/` | global agents, every session |
| `~/.config/opencode/ahold/*.md` | `system/opencode/ahold/` | Ahold overlay (any number of files), **work lane only** |

How the layers stack (verified against opencode 1.17.5):

- OpenCode always loads `~/.config/opencode/AGENTS.md`, then walks **up**
  from the cwd to the project root collecting any project `AGENTS.md`, and
  combines them all. A project-level `CLAUDE.md` is **not** auto-loaded in
  this version — project instruction files must be named `AGENTS.md`.
- Agents are discovered via the glob `{agent,agents}/**/*.md` under the
  config dir and any project `.opencode/`, so the curated agents are
  available everywhere.
- The Ahold overlay is **not** global. It's pulled in only by the work
  lane, via `instructions: ["…/ahold/*.md"]` in
  `~/projects/ahold/opencode.json` (declared in
  [`nix/home/codemem.nix`](../nix/home/codemem.nix)). A new client gets its
  own overlay file plus a new lane.

Agents intentionally **omit a `model:` field** so they inherit the active
lane's default model. Hard-coding `anthropic/…` would route an agent to the
personal Max proxy even under `oc-work` — a client-data leak. Leaving it
unset preserves lane isolation.

These are the **global** agents (both lanes). For **project-scoped,
per-client** agents and repo rules — materialized into a client checkout
from a private repo without committing them — see
[OpenCode client tooling](opencode-client-tooling.md).

## OpenCode agent workflow

A schema-driven, multi-agent way to take a feature from spec to merged: a
**lead** orchestrator (Opus) plans, dispatches role subagents
(`planner`/`architect`/`developer`/`reviewer`/`closer`) and the specialists
above, and enforces an escalation ladder + review gates. Roles live in
`system/opencode/agent/`, commands (`/plan`, `/review`, `/close`) in
`system/opencode/command/`, and the per-lane Opus/Sonnet tiers in each
`opencode.json`'s `agent.<role>.model` block (model-less agents + per-lane tiers
= isolation-safe). **Subagent models don't show in the footer — verify via the
log** (`grep 'agent=<role>' ~/.local/share/opencode/log/opencode.log`).

Full reference: [OpenCode agent workflow](opencode-agent-workflow.md).

## Repo-level Claude config

- `CLAUDE.md` at the repo root is the agent entry point; it defers to
  `docs/` for detail. `AGENTS.md` is a symlink to it so OpenCode (which
  auto-loads `AGENTS.md`, not project `CLAUDE.md`) reads the same guidance.
- `.gitignore` excludes `/.claude/` at the repo root (machine-local
  Claude Code worktree state) — distinct from `system/.claude/`, which
  is versioned.
- The global git ignores (per-host `git.nix`) exclude
  `**/.claude/settings.local.json` and `**/CLAUDE.local.md` in *other*
  repos; this repo's `system/.claude/settings.local.json` is tracked
  because it's the source the symlink points to, not a local override.
