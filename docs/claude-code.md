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

## Reference snapshot (runtime-rewritten settings)

`~/.claude/settings.json` is rewritten by Claude Code at runtime (plugin
toggles, effort level, etc.), so it **must not** be a Nix-store symlink.
The repo keeps a reference snapshot, `system/.claude/settings.json`, and
every rebuild **merges** the keys the lane module owns into
`~/.claude/settings.json` and `~/.claude-work/settings.json` (see
[Settings merge](#settings-merge)). When `~/.claude/settings.json`
doesn't exist yet the merge starts from the snapshot, so a fresh machine
needs no manual step.

Manual re-seed (then rebuild so the lane's owned keys are merged back in):

```bash
cp ~/.dotfiles/system/.claude/settings.json ~/.claude/settings.json
```

To refresh the snapshot after changing settings in the app: copy the
runtime file back into the repo and commit (strip the keys owned by
`claude-lanes.nix` — `env`, `hooks`, `permissions.deny`, `sandbox`).

Everything else under `~/.claude/` (transcripts, session state, plugin
caches) is deliberately unmanaged.

## Two Claude Code lanes

Declared in [`nix/home/claude-lanes.nix`](../nix/home/claude-lanes.nix)
(a shared home-manager module, applied on every host). Claude Code runs
in **two isolated lanes** so client (Ahold) content only ever goes
through the sanctioned TechNL proxy — never to Anthropic directly, and
never through the personal Max login:

| Lane | Config dir | Inference | Start it with | codemem DB | Viewer port |
|---|---|---|---|---|---|
| personal | `~/.claude` | Claude Max login | the Claude desktop app in its normal mode, T3 Code, plain `claude`, or `cc-personal` | `~/.codemem/personal/` | 4747 |
| work (Ahold) | `~/.claude-work` | the TechNL gateway, via DevAI CLI | `cc-work` (terminal) or `cc-work-desktop` (the desktop app in gateway mode) | `~/.codemem/work-ahold/` | 4848 |

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

**The desktop app is one lane at a time.** It runs in one *deployment
mode*: `1p` (your Claude account, app profile
`~/Library/Application Support/Claude`) or `3p` (a gateway, separate
profile `…/Claude-3p` with its own chats, login and settings).
Switching relaunches the app. So it is either the personal lane or —
through `cc-work-desktop` — the work lane, never both at once. While
it's in work mode, use T3 Code (or `claude` / `cc-personal`) for
personal projects; personal chat still works at claude.ai in a browser.

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
  - `CLAUDE_CONFIG_DIR=~/.claude-work`;
  - `CODEMEM_ANTHROPIC_ENDPOINT` (codemem's observer endpoint);
  - the work env, which is also in the work `settings.json` so every
    work session gets it however it was launched: `CC_LANE=work`, the
    per-lane codemem env (below), model aliases `opus` →
    `claude-opus-5-5`, `sonnet` → `claude-sonnet-5-5`, `haiku` →
    `claude-haiku-4-5` (`ANTHROPIC_DEFAULT_*_MODEL`; `/model` can still
    pick any other id the gateway serves — `devai status` lists them),
    and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` (no telemetry,
    error reports, auto-updates or feature-flag calls to Anthropic).

  The gateway variables (`ANTHROPIC_BASE_URL`, credentials) are left to
  `devai-claude`. Its arguments are Claude Code's (`cc-work -p …`,
  `cc-work --resume`) — it runs `devai-claude -- "$@"`; call
  `devai-claude` directly for DevAI's own options (e.g. `-v`). It refuses
  to start while anything listens on port
  38888 (see the [codemem known issue](#codemem-memory)).

  Verified: `devai-claude` keeps the `CLAUDE_CONFIG_DIR` and env it is
  given, and sessions get `ANTHROPIC_BASE_URL` = DevAI's local proxy.
- **`cc-work-desktop`** — the same preparation, then
  `devai-claude-desktop --detach`: DevAI starts its local proxy (kept
  running after the shell exits), switches the desktop app to its
  gateway profile and **restarts the app** (it asks first; pass
  `--kill-existing-desktop` to skip the prompt). Run it from a regular
  terminal — the desktop app's own terminal pane closes with the app.
  **One-time step in work mode:** the Code tab must use
  `~/.claude-work`, or it falls back to `~/.claude` (personal plugins,
  the personal memory lane, and the Ahold guard blocking every work
  repo). In the work-mode app, open the environment selector → *Local*
  → settings, and add `CLAUDE_CONFIG_DIR` = the **absolute** path
  `/Users/<you>/.claude-work` (the app ignores `~` or relative paths).
  That editor belongs to the work profile, so personal mode is not
  affected. Check it with `echo $CLAUDE_CONFIG_DIR` in a work Code
  session.
  To go back to personal mode, switch the app back to your Claude
  account (the gateway setting under Developer → Configure Third-Party
  Inference); `devai status` shows the desktop state.
- **`cc-lanes-setup`** — one-time per machine, after the first rebuild:
  installs the codemem plugin into both lanes (plugins are per config
  dir).

### Guards

Each lane has hooks that block a prompt or tool call (exit 2) before
anything is sent — verified: a blocked prompt makes zero API calls.

- **Work: `lane-check.sh`** (`UserPromptSubmit` + `PreToolUse`) — blocks
  unless the session has a gateway URL (`ANTHROPIC_BASE_URL` or
  `CLAUDE_CODE_API_BASE_URL`) that isn't `anthropic.com` and a
  `CODEMEM_ANTHROPIC_ENDPOINT` that isn't `anthropic.com`. That covers
  both launchers; a personal-mode desktop session using the work config
  gets `ANTHROPIC_BASE_URL=https://api.anthropic.com` and plain `claude`
  gets none, so both are blocked. Also blocks while port 38888 is
  listening.
- **Personal lane** — keeps client work trees (`workRoots` in
  `claude-lanes.nix`, exported as `CC_WORK_ROOTS`) out of Max, in three
  layers:
  1. **Permission deny rules** — `Read(//<root>/**)` and
     `Edit(//<root>/**)`, merged into `~/.claude/settings.json`. Claude
     Code resolves these paths itself (relative, `~`, symlinks), and Read
     rules also cover Grep, Glob and LSP. This is the boundary for the
     file tools.
  2. **Bash sandbox** (macOS Seatbelt) — `sandbox.enabled` with each root
     in `sandbox.filesystem.denyRead`, so a shell command (and anything it
     starts: scripts, interpreters) can't read the work tree, whatever
     path it uses. `allowUnsandboxedCommands: false` removes the escape
     hatch of retrying a failed command outside the sandbox. Both are
     forced on every rebuild; toggling them off in `/sandbox` only lasts
     until the next one.
  3. **`work-lane-guard.sh`** (`UserPromptSubmit` + `PreToolUse`, logic in
     `work-lane-guard.jq`) — what neither covers: prompts (including `@`
     mentions), MCP tool arguments, and case-insensitive matching (APFS).
     It also checks Bash and the file tools as defence in depth: it
     expands `~`/`$HOME`, resolves relative paths against the session cwd
     (following `cd`), and blocks searches that would descend into a root
     from a parent folder (`rg`/`find`/`grep -r` in `~`, Grep/Glob from
     `~/projects`). It fails closed: if jq or the `.jq` file is missing,
     or the input can't be parsed, the request is blocked.

  What the sandbox changes for personal-lane Bash: commands can write
  only to the project folder, `$TMPDIR`, `~/.m2`, `~/.gradle` and
  `~/.npm`, and reach only Maven Central, Gradle and npm without asking
  (other hosts prompt per domain). Add more in `claude-lanes.nix`
  (`union.sandbox.filesystem.allowWrite`, `…network.allowedDomains`), or
  in `/sandbox` — your own entries survive rebuilds. Known macOS
  frictions: Docker and Go CLIs such as `gh` don't work inside Seatbelt,
  and `git push` with the keychain helper is untested — run those
  yourself, or list them in `sandbox.excludedCommands` (which runs them
  fully unsandboxed). Bash prompts stay as they were
  (`autoAllowBashIfSandboxed: false`, only written when unset).

  Practical effects: start personal sessions in a project folder, not in
  `~` or `~/projects` (recursive searches from there are blocked), and a
  command whose text literally contains a work-root path — e.g. grepping
  these dotfiles for `~/projects/ahold` — is blocked too. Fixtures for
  both hooks live in [`tests/guard.sh`](../tests/guard.sh).

### Settings merge

`~/.claude*/settings.json` are app-owned and mutable, so they can't be
symlinks. Instead the `claudeLaneSettings` activation step merges **only
the keys the module owns** into whatever is there:

- `env` — the lane's env keys overwrite; other env keys are kept, and
  a key the lane stops owning is removed on the next rebuild (the last
  owned set is in `.nix-owned.json` next to the settings file);
- `hooks` — hook entries whose command lives under the lane's `hooks/`
  dir are replaced; any other hooks (plugins, your own) are kept, even
  in the same matcher group;
- personal lane only: `permissions.deny` and the sandbox lists
  (`filesystem.denyRead`/`allowWrite`, `network.allowedDomains`) get the
  owned entries appended when missing — your own entries are kept;
  `sandbox.enabled` and `sandbox.allowUnsandboxedCommands: false` are
  forced; `sandbox.autoAllowBashIfSandboxed: false` is written only when
  unset;
- work lane only: `skipWebFetchPreflight: true` (the preflight sends the
  target hostname to `api.anthropic.com`), and `model: "opus"` written
  only when unset (so `/model` keeps working).

It's idempotent and leaves plugins, your own permission rules and the
rest of the file alone. A settings file that isn't valid JSON (say, a
half-finished hand edit) is moved to `settings.json.invalid-<time>` and
rebuilt from the snapshot, with a warning, instead of failing the
rebuild. The merge is
[`system/bin/merge-claude-settings.sh`](../system/bin/merge-claude-settings.sh);
[`tests/merge.sh`](../tests/merge.sh) covers it.

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
`pass-cli` declared in that host's `homebrew.nix`, and Node 24.15+ (the
plugin's hooks run `node`, its MCP server `npx`) — mise's global Node
LTS covers it once `mise install` has run.

### Migrated from OpenCode

These lanes replaced an earlier OpenCode setup, which is fully removed.
Leftovers not managed by Nix can be deleted by hand:
`~/.local/share/opencode`, `~/.cache/opencode`, and any
`~/.config/opencode` remnants.

### Removed: claude-mem

codemem is the only memory system; claude-mem (personal lane only, one
machine-wide worker, Sonnet extraction) was removed along with its `bun`
and `uv` brews. On a machine that still has it, once:

```bash
npx claude-mem uninstall   # stops the worker, removes the plugin and its settings entries
rm -rf ~/.claude-mem       # its memories, if you don't want to keep them
```

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
  `**/.claude/settings.local.json` and `**/CLAUDE.local.md` in every
  repo: they hold per-machine approvals and notes.
