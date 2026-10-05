# Agent workflow

A schema-driven, multi-agent way to take a feature from spec to merged inside
Claude Code. The **lead** (the main session, driven by `/flow`) decomposes the
work, dispatches role subagents and specialist agents, and enforces an
escalation ladder plus review gates.

It's modelled on a role→model + capped-loop orchestration schema, trimmed to
**Sonnet + Opus only** (no codex tier, no heavy "wave" ceremony). It works in
**both lanes** (personal `~/.claude` and work `cc-work`), with the model tiers
resolved per lane so work stays inside the sanctioned TechNL channel.

See also: [Two Claude Code lanes](claude-code.md#two-claude-code-lanes)
(the lane setup this builds on) and
[Client tooling](client-tooling.md) (per-client project agents).

## The roles

Five subagents plus the lead, shared by both lanes: `system/.claude/agents/` is
symlinked to `~/.claude/agents` ([`nix/home/files.nix`](../nix/home/files.nix))
and `~/.claude-work/agents` ([`nix/home/claude-lanes.nix`](../nix/home/claude-lanes.nix)):

| Role | Runs as | Tier | What it does |
|---|---|---|---|
| lead | main session via `/flow <spec>` | your session's model | plans, dispatches, gatekeeps |
| `planner` | subagent | **Opus** | spec → dependency-ordered tasks grouped into phases (+ acceptance criteria) |
| `architect` | subagent | Sonnet | per-phase design + acceptance criteria, before any code in that phase |
| `developer` | subagent | Sonnet | implements ONE task: code + tests + a focused commit |
| `reviewer` | subagent | Sonnet | plan-review or change-review gate — returns **PASS/BLOCK** |
| `closer` | subagent | Sonnet | closes a phase: checks tests + the gate verdict, advances or blocks, writes a handoff |

**Why the lead is a command, not an agent:** Claude Code subagents can't
dispatch other subagents. So the orchestrator has to be the main session — the
`/flow` command loads the lead's instructions into it. For the same reason the
lead (not the roles) routes specialist craft: when a task needs deep domain
expertise it dispatches a specialist (`typescript-pro`, `spring-boot-engineer`,
`kotlin-architect`, `react-specialist`, `sql-pro`, `test-automator`,
`code-reviewer`, `architect-reviewer`, … — see `/agents`) instead of
`developer`/`reviewer`.

## How the pieces fit

1. **Role prompts** — `system/.claude/agents/{planner,architect,developer,reviewer,closer}.md`.
   Claude Code frontmatter: `name`, `description`, `tools`, and a `model:` set
   to an alias (`opus` / `sonnet`).
2. **Slash commands** — `system/.claude/commands/flow*.md`, both lanes:
   - `/flow <spec>` → the full lead flow, with the escalation ladder + caps.
   - `/flow-plan <spec>` → dispatches `planner`, returns the phased plan.
   - `/flow-review [target]` → dispatches the `reviewer` gate (defaults to the
     current diff).
   - `/flow-close [notes]` → `reviewer` gate on the phase, then `closer`.

   They're prefixed `flow-` so they don't collide with the built-in `/review`.

### Why tiers are aliases (isolation)

This is **load-bearing for client isolation**. Agent files only ever name an
alias, never a full provider model id. Each lane maps the aliases to its own
endpoint:

- personal → Anthropic's Opus / Sonnet via the Max login.
- work (`cc-work` / `cc-work-desktop`) → `ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU}_MODEL` =
  `claude-opus-5-5` / `claude-sonnet-5-5` / `claude-haiku-4-5`, all served by
  the TechNL gateway (set in the work `settings.json` env, so CLI and desktop
  work sessions both get them; `/model` can still pick other gateway ids).

Every request from the work lane — main session or subagent, whatever the
tier — goes to the lane's `ANTHROPIC_BASE_URL`, so an alias can't route client
work elsewhere. Hard-coding a full model id in an agent file would bypass the
per-lane mapping — don't.

> The work-lane Opus id (`claude-opus-5-5`) must match what TechNL serves, and
> needs Claude Code CLI >= 2.1.285 (older builds reject it as
> `unrecognized_model`). Change the mapping in `claude-lanes.nix` if TechNL
> exposes Opus under a different id.

## The escalation ladder + capped loops

Encoded in `/flow`'s prompt as **hard ceilings**:

```
per task:   sonnet ×3   →   opus ×1   →   FAILED (recompute deps, move on)
            task_retry_sonnet=3   task_retry_opus=1

loops:      plan_review_rounds      = 3   (plan ↔ reviewer)
            checklist_review_rounds = 2   (phase design ↔ reviewer)
            review_rounds           = 5   (phase gate fix-loop)
```

The Opus escalation is a `developer` dispatch with the model overridden to
`opus`. Enforcement is *soft* — the lead self-polices the caps from its prompt;
nothing mechanically stops it. See [Phase 2](#phase-2--deferred) for the
deterministic version.

`/flow` also triages first: trivial changes are done directly, small tasks get
one `developer` + one `reviewer` pass, and only substantial features run the
full plan → design → implement → gate → close machine. The caps are ceilings,
not targets.

## How to use it

1. Start your lane (desktop app / `claude` / `cc-personal`, or `cc-work`) in the
   target repo.
2. Run `/flow <feature or spec>`. For a substantial feature the lead will:
   1. **Plan** — dispatch `planner`, then plan-review with `reviewer`
      (fix-loop up to `plan_review_rounds`).
   2. **Per phase** — dispatch `architect` for the design, checklist-review it
      with `reviewer` (up to `checklist_review_rounds`).
   3. **Per task** — dispatch `developer` under the escalation ladder; on
      success it commits.
   4. **Close** — `reviewer` gate on the phase (fix-loop up to
      `review_rounds`), then `closer` advances with a handoff or blocks.
3. Repeat until all phases close; the lead summarises what shipped and what
   FAILED.

You don't have to run the whole machine — the commands are useful standalone:
`/flow-plan` for a phased plan, `/flow-review` as a release gate on your
current diff, `/flow-close` to wrap a chunk of work. You can also ask for any
role directly ("use the reviewer subagent on …").

### A quick smoke test

```
cc-work        # or the desktop app / cc-personal
/flow build a tiny slugify() helper with a test
# watch: developer edits + tests + commits → reviewer PASS/BLOCK
```

## Verifying which model an agent actually used

Don't infer a subagent's model from the session's own model. Check it:

- **Interactively:** `/status` shows the session's model and endpoint.
- **Headless (ground truth per model):** run a prompt that dispatches the role
  and read `modelUsage` from the JSON result:

  ```bash
  cc-work -p "use the planner subagent to plan: add a /health endpoint" \
    --output-format json | jq '.modelUsage | keys'
  # → [ "claude-opus-5-5", "claude-sonnet-5-5", … ]
  ```

  An Opus id appearing confirms the `planner` tier; under `cc-work` the ids are
  the TechNL ones, confirming the alias mapping.

## Where everything lives

| Piece | Path |
|---|---|
| Role subagents | `system/.claude/agents/{planner,architect,developer,reviewer,closer}.md` |
| Lead + step commands | `system/.claude/commands/{flow,flow-plan,flow-review,flow-close}.md` |
| Deployment, personal | [`nix/home/files.nix`](../nix/home/files.nix) (`~/.claude/{agents,commands}`) |
| Deployment, work | [`nix/home/claude-lanes.nix`](../nix/home/claude-lanes.nix) (`~/.claude-work/{agents,commands}`) |
| Per-lane alias → model mapping | [`nix/home/claude-lanes.nix`](../nix/home/claude-lanes.nix) (`ANTHROPIC_DEFAULT_*_MODEL` in the work env) |

## Extending it

- **Add a role:** drop `system/.claude/agents/<role>.md` (frontmatter `name`,
  `description`, `tools`, `model: sonnet` or `opus`), `git add`, rebuild. It
  appears in both lanes. Mention it in `/flow` if the lead should dispatch it.
- **Change a role's tier:** edit its `model:` alias. Aliases only — never a full
  model id.
- **New client lane:** a new lane (see
  [client tooling → onboard](client-tooling.md#runbook--onboard-a-new-client))
  gets these roles by linking the same `agents/` and `commands/` dirs. Give it
  its own `ANTHROPIC_DEFAULT_*_MODEL` mapping pointing at *its* channel's ids.
- **Add a command:** drop `system/.claude/commands/<name>.md` (frontmatter:
  `description`, optional `argument-hint`; body is the prompt, `$ARGUMENTS` is
  substituted), `git add`, rebuild. Avoid names of built-in commands.

## Phase 2 — deferred

The current escalation enforcement is soft (the lead self-polices its caps). The
deterministic version, not yet built:

- **`flow-task`** — a headless runner (`claude -p --agent developer --model
  <tier>` in the right lane) that *enforces* the retry caps and does the real
  per-attempt sonnet→opus swap, gating on build/test signal between attempts.
- **`flow-commit`** — a focused commit helper (the schema's `sb-commit.sh`
  equivalent).

Both would ship like [`cc-tooling`](client-tooling.md) — a
`writeShellScriptBin` in `nix/home/claude-lanes.nix` from a script in
`system/bin/`.
