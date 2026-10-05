# Claude Code integration

Claude Code configuration is version-controlled in `system/.claude/`
(personal lane) and `system/.claude-work/` (work lane). It is wired
into `~/.claude/` and `~/.claude-work/` three different ways,
depending on whether the app rewrites the file at runtime: read-only
symlinks, seeded snapshots, and an activation-time settings merge.

## Managed via home-manager symlinks (static files)

Declared in [`nix/home/files.nix`](../nix/home/files.nix) and
[`nix/home/claude-lanes.nix`](../nix/home/claude-lanes.nix); applied on
every rebuild:

- `~/.claude/settings.local.json` ← `system/.claude/settings.local.json`
  (active permission allowlist)
- `~/.claude/settings.template.json` ← `system/.claude/settings.template.json`
  (starter allowlist for new machines)
- `~/.claude/README.md` ← `system/.claude/README.md`
- `~/.claude/CLAUDE.md` ← `system/.claude/CLAUDE.md` (global baseline
  instructions, both lanes)
- `~/.claude/agents` ← `system/.claude/agents/` (custom subagents,
  whole directory, read-only)
- `~/.claude/commands` ← `system/.claude/commands/` (slash commands)
- `~/.claude/skills` ← `system/.claude/skills/` (the `vault-*`
  Obsidian skills, etc.)
- `~/.claude/hooks` ← `system/.claude/hooks/` (personal-lane guard)

The work-lane equivalents (`~/.claude-work/…`) are listed under
[Two Claude Code lanes](#two-claude-code-lanes).

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

On top of that, every rebuild **merges** the keys the lane module owns
into `~/.claude/settings.json` and `~/.claude-work/settings.json` (see
[Settings merge](#settings-merge)). Activation runs before `setup.sh`'s
seed step, so when `~/.claude/settings.json` doesn't exist yet the merge
starts from the reference snapshot itself; a fresh machine needs no
manual step.

Manual re-seed:

```bash
cp ~/.dotfiles/system/.claude/settings.json ~/.claude/settings.json
cp ~/.dotfiles/system/.claude-mem/settings.json ~/.claude-mem/settings.json
# then fix any /Users/<other-user> paths inside if seeding by hand,
# and rebuild so the lane env + hooks are merged back in
```

To refresh a snapshot after changing settings in the app: copy the
runtime file back into the repo and commit (strip the merged `env` and
`hooks` keys — those are owned by `claude-lanes.nix`).

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

Note: `bun` and `uv` are pinned in `nix/hosts/m5/homebrew.nix`. Add
them to any new host's `homebrew.nix` before running the claude-mem
installer there, or claude-mem will auto-fetch unpinned copies for its
worker daemon and vector search.

## Two Claude Code lanes

Declared in [`nix/home/claude-lanes.nix`](../nix/home/claude-lanes.nix)
(a shared home-manager module, applied on every host). Claude Code runs
in **two isolated lanes** so client (Ahold) content only ever goes
through the sanctioned TechNL proxy — never to Anthropic directly, and
never through the personal Max login:

| Lane | Config dir | Inference | Start it with | codemem DB | Viewer port |
|---|---|---|---|---|---|
| personal | `~/.claude` | Claude Max login | the Claude desktop app (preferred), plain `claude`, or `cc-personal` | `~/.codemem/personal/` | 4747 |
| work (Ahold) | `~/.claude-work` | the TechNL gateway, via DevAI CLI (`devai-claude`) | `cc-work` only, in a terminal | `~/.codemem/work-ahold/` | 4848 |

Settings, plugins, transcripts, auto-memory and the Keychain credential
are all per config dir, so the work lane never sees the personal Max
login or personal plugins.

**Gateway vs isolation.** Ahold's DevAI CLI is the sanctioned way into
the TechNL gateway: `devai setup` once (Entra ID keyless sign-in, or a
static key), then `devai-claude` starts Claude Code through a temporary
local compatibility proxy. DevAI owns auth, the proxy and model
routing; `devai status` / `devai quota` show login state and budget. It
does **not** separate Claude Code's config — run on its own it would
load `~/.claude` (personal plugins, skills, and the personal codemem
lane, whose observer extracts via Max). So `cc-work` wraps
`devai-claude` with the isolation layer. Install DevAI CLI per its
docs (`npm install -g @royalaholddelhaize/devai-cli`, needs a GitHub
Packages token) before using `cc-work`.

**Why the desktop app can't host the work lane:** it has one app-wide
inference setup — the Max login *or* a single third-party gateway
(Developer → Configure Third-Party Inference) — with no per-folder
routing and no `CLAUDE_CONFIG_DIR`. So the desktop app is the personal
lane, and the work lane is the CLI under `cc-work`, run in any terminal
(including the desktop app's own terminal pane).

Requires Claude Code CLI **>= 2.1.285** (the `claude-code` cask) —
older builds (e.g. 2.1.274) reject `claude-opus-5-5` as
`unrecognized_model`.

### The launchers (zsh functions)

- **`cc-personal`** — runs `claude` with every lane/gateway variable
  stripped from the calling shell and the personal codemem env set.
  Plain `claude` and the desktop app get the same env from
  `~/.claude/settings.json`.
- **`cc-work`** — refuses to start unless `devai-claude` is installed.
  It resolves the TechNL proxy URL from `pass-cli`
  (`pass://Ahold/TechNLGenAI/proxy_url`) for codemem's observer and
  **fails closed** if that is missing or malformed — without it the
  observer would default to `api.anthropic.com`. It pins that endpoint
  into `~/.claude-work/settings.json` (`env.CODEMEM_ANTHROPIC_ENDPOINT`,
  a local file, never in the repo), then strips inherited lane and
  gateway variables and runs `devai-claude` with:
  - `CLAUDE_CONFIG_DIR=~/.claude-work`, `CC_LANE=work`;
  - `CODEMEM_ANTHROPIC_ENDPOINT` (codemem's observer endpoint);
  - model aliases `opus` → `claude-opus-5-5`, `sonnet` →
    `claude-sonnet-4-6`, `haiku` → `claude-haiku-4-5`
    (`ANTHROPIC_DEFAULT_*_MODEL`), on the launch env only so DevAI's own
    model routing wins if it sets any;
  - `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` (no telemetry, error
    reports, auto-updates or feature-flag calls to Anthropic);
  - the per-lane codemem env (below), which is also in the work
    `settings.json` in case `devai-claude` rebuilds the environment.

  The gateway variables (`ANTHROPIC_BASE_URL`, credentials) are left to
  `devai-claude`. Its arguments are Claude Code's (`cc-work -p …`,
  `cc-work --resume`) — it runs `devai-claude -- "$@"`; call
  `devai-claude` directly for DevAI's own options (e.g. `-v`). It refuses
  to start while anything listens on port
  38888 (see the [codemem known issue](#codemem-memory)).

  **Verify on first use** (DevAI's internals weren't inspected from the
  personal lane): `/status` shows a non-Anthropic base URL, and
  `devai-claude` keeps the `CLAUDE_CONFIG_DIR` it is given — if it
  forces its own, the work hooks and codemem plugin won't load.
- **`cc-lanes-setup`** — one-time per machine, after the first rebuild:
  installs the codemem plugin into both lanes (plugins are per config
  dir).

### Guards

Each lane has hooks that block a prompt or tool call (exit 2) before
anything is sent — verified: a blocked prompt makes zero API calls.

- **Work: `lane-check.sh`** (`UserPromptSubmit` + `PreToolUse`) — blocks
  unless the session was started by `cc-work`: `CC_LANE=work`, an
  `ANTHROPIC_BASE_URL` (DevAI's local proxy) that isn't `anthropic.com`,
  and a `CODEMEM_ANTHROPIC_ENDPOINT` that isn't `anthropic.com`. Also
  blocks while port 38888 is listening.
- **Personal: `work-lane-guard.sh`** (`UserPromptSubmit` + `PreToolUse`)
  — blocks any prompt or tool call that touches a client work tree
  (`~/projects/ahold`, from `CC_WORK_ROOTS`), so opening an Ahold repo
  in the desktop app can't send it through Max.

### Settings merge

`~/.claude*/settings.json` are app-owned and mutable, so they can't be
symlinks. Instead the `claudeLaneSettings` activation step merges **only
the keys the module owns** into whatever is there:

- `env` — the lane's env keys overwrite; other env keys are kept;
- `hooks` — entries whose command lives under the lane's `hooks/` dir
  are replaced; any other hooks (plugins, your own) are kept;
- work lane only: `skipWebFetchPreflight: true` (the preflight sends the
  target hostname to `api.anthropic.com`), and `model: "opus"` written
  only when unset (so `/model` keeps working).

It's idempotent and leaves plugins, permissions and the rest of the
file alone.

### Instructions & agents per lane

| Path | personal (`~/.claude`) | work (`~/.claude-work`) |
|---|---|---|
| `CLAUDE.md` | `system/.claude/CLAUDE.md` | that baseline + every `system/.claude-work/ahold/*.md`, concatenated |
| `agents/`, `commands/` | `system/.claude/{agents,commands}/` | same (shared) |
| `skills/` | `system/.claude/skills/` | none — the `vault-*` skills read the personal Obsidian vault |
| `hooks/` | `system/.claude/hooks/` | `system/.claude-work/hooks/` |
| `settings.json` | app-owned, owned keys merged | app-owned, owned keys merged |

- The Ahold overlay (`system/.claude-work/ahold/`) is **work lane only**.
  Add files alongside the existing ones; every `*.md` there is appended
  in name order.
- Ahold repos keep their instructions in `AGENTS.md`, which Claude Code
  doesn't auto-load. The work lane's `agents-md.sh` `SessionStart` hook
  injects the repo-root `AGENTS.md` (skipped if the repo's `CLAUDE.md`
  already imports `@AGENTS.md`); the overlay tells Claude to read nested
  `AGENTS.md` files before working in a subdirectory.
- Agents set `model:` to an **alias** only (`opus` / `sonnet`), never a
  full model id. The alias resolves per lane — the Max models in the
  personal lane, the TechNL ids above in the work lane — so an agent
  can't route client work out of the sanctioned channel.

For **per-client custom agents and repo-specific rules** (kept out of
these public dotfiles, in a private per-client repo), see
[Client tooling](client-tooling.md).

### codemem memory

[codemem](https://www.npmjs.com/package/codemem) gives Claude Code
persistent memory, per lane. Its side lives in
[`nix/home/codemem.nix`](../nix/home/codemem.nix): the per-lane observer
configs (`~/.config/codemem/{personal,work-ahold}.json`) and runtime
dirs. The lane module exports, per lane, `CODEMEM_DB`, `CODEMEM_CONFIG`,
`CODEMEM_VIEWER_PORT`, `CODEMEM_PLUGIN_LOG` and
`CODEMEM_CLAUDE_HOOK_{SPOOL,LOCK,CONTEXT}_DIR` — codemem's defaults for
the latter are shared across lanes and would cross-contaminate.

| Lane | Observer | Extraction goes through |
|---|---|---|
| personal | `claude_sidecar`, `claude-haiku-4-5` | local Claude (Max) |
| work | `api_http` / `anthropic`, `claude-haiku-4-5`, `api-key` header | the TechNL proxy (`CODEMEM_ANTHROPIC_ENDPOINT` set by `cc-work`) |

The codemem plugin is installed per lane with `cc-lanes-setup`. Its MCP
server auto-starts each lane's viewer on that lane's port, and the
extraction sweep runs inside that viewer (~2 min after a session goes
idle) — so work extraction stays in the TechNL channel.

**Known issue:** codemem <= 0.36 hook ingest ignores
`CODEMEM_VIEWER_PORT` and posts to `127.0.0.1:38888`. A fix is pending
upstream; until it ships, `cc-work` refuses to start and `lane-check.sh`
blocks while anything listens on 38888, so work events can't land in a
stray viewer.

**No secrets live in the repo.** The TechNL key *and* the proxy URL are
resolved at runtime via `pass-cli` (Proton Pass), and paths use
`config.home.homeDirectory` rather than a hardcoded `/Users/<name>`, so
the modules survive a change of host or username. Prereqs on a host:
`pass-cli` and `uv` declared in that host's `homebrew.nix`.

### Migrated from OpenCode

These lanes replaced an earlier OpenCode setup, which is fully removed.
Leftovers not managed by Nix can be deleted by hand:
`~/.local/share/opencode`, `~/.cache/opencode`, and any
`~/.config/opencode` remnants.

## Agent workflow

A schema-driven, multi-agent way to take a feature from spec to merged:
the `/flow <spec>` command makes the main session the **lead**, which
dispatches role subagents (`planner` on Opus; `architect`/`developer`/
`reviewer`/`closer` on Sonnet) and the specialists, and enforces an
escalation ladder + review gates. `/flow-plan`, `/flow-review` and
`/flow-close` run single steps. Roles live in `system/.claude/agents/`,
commands in `system/.claude/commands/`; tiers are model aliases resolved
per lane.

Full reference: [Agent workflow](agent-workflow.md).

## Repo-level Claude config

- `CLAUDE.md` at the repo root is the agent entry point; it defers to
  `docs/` for detail. `AGENTS.md` is a symlink to it so tools that read
  the cross-tool `AGENTS.md` convention see the same guidance.
- `.gitignore` excludes `/.claude/` at the repo root (machine-local
  Claude Code worktree state) — distinct from `system/.claude/`, which
  is versioned.
- The global git ignores (per-host `git.nix`) exclude
  `**/.claude/settings.local.json` and `**/CLAUDE.local.md` in *other*
  repos; this repo's `system/.claude/settings.local.json` is tracked
  because it's the source the symlink points to, not a local override.
