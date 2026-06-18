# OpenCode agent workflow

A schema-driven, multi-agent way to take a feature from spec to merged inside
OpenCode. A **lead** orchestrator decomposes the work, dispatches role
subagents (which in turn delegate to the specialist agents), and enforces an
escalation ladder plus review gates.

It's modelled on a role→model + capped-loop orchestration schema, trimmed to
**Sonnet + Opus only** (no codex tier, no heavy "wave" ceremony). It works in
**both lanes** (`oc-personal` and `oc-work`), with the model tiers chosen
per-lane so work stays inside the sanctioned TechNL channel.

See also: [OpenCode instructions & agents](claude-code.md#opencode-instructions--agents)
(the global agent layer this builds on) and
[OpenCode client tooling](opencode-client-tooling.md) (per-client project agents).

## The roles

Six roles, deployed as **global** agents (read by every session, both lanes)
from `system/opencode/agent/` via [`nix/home/opencode.nix`](../nix/home/opencode.nix):

| Role | Mode | Tier | What it does |
|---|---|---|---|
| `lead` | primary | **Opus** | the session you orchestrate from (Tab to it); plans, dispatches, gatekeeps |
| `planner` | subagent | **Opus** | spec → dependency-ordered tasks grouped into phases (+ acceptance criteria) |
| `architect` | subagent | Sonnet | per-phase design + acceptance criteria, before any code in that phase |
| `developer` | subagent | Sonnet | implements ONE task: code + tests + a focused commit |
| `reviewer` | subagent | Sonnet | plan-review or change-review gate — returns **PASS/BLOCK** |
| `closer` | subagent | Sonnet | closes a phase: runs the gate, advances or blocks, writes a handoff |

The roles **orchestrate**; the actual craft is delegated **down to the existing
specialist agents** (`typescript-pro`, `spring-boot-engineer`, `kotlin-architect`,
`react-specialist`, `sql-pro`, `test-automator`, `code-reviewer`,
`architect-reviewer`, … — see `/agents`). No logic is duplicated.

## How the pieces fit

Three layers, deliberately separated so the same agents work in both lanes
without leaking client work to the wrong provider:

1. **Role prompts** — `system/opencode/agent/*.md`. These define each role's
   behaviour and are **model-less** (like every global agent). `lead.md` also
   carries the escalation ladder + caps in its prompt.
2. **Per-lane model tiers** — each lane's `opencode.json` maps roles to models
   via an `agent.<role>.model` block (declared in
   [`nix/home/codemem.nix`](../nix/home/codemem.nix)). Only `lead` + `planner`
   are pinned to Opus; every other role omits a model and inherits the lane's
   Sonnet default.
3. **Slash commands** — `system/opencode/command/*.md`, deployed to
   `~/.config/opencode/command/` (both lanes):
   - `/plan <spec>` → runs `planner` as a subtask.
   - `/review [target]` → runs the `reviewer` gate (defaults to current diff).
   - `/close` → runs the `closer` on the current phase.

### Why tiers live in config, not in the agent files (isolation)

This is **load-bearing for client isolation**. The role files are model-less;
the tier is chosen per-lane:

- `oc-personal` → `lead`/`planner` = `anthropic/claude-opus-4-8` (via the Max proxy).
- `oc-work` → `lead`/`planner` = `technl/claude-opus-4-8` (via the TechNL proxy).

Under `oc-work`, OpenCode loads the **personal** config as the base and merges
the **work** config on top (config scalars override; `instructions` arrays
concatenate). So `lead`/`planner` must be pinned to `technl/*` **in the work
config** — if they were left unset there they'd inherit the personal
`anthropic/*` Opus and route client work to the Max proxy, a leak. Every other
role omits a model, so it inherits the work lane's `technl/claude-sonnet-4-6`
default. Hard-coding a model in a role file would break this — don't.

> The Opus model id (`claude-opus-4-8`) must match what each provider serves.
> The `technl` provider passes model ids through, so the `models` block in
> `opencode.json` only sets display names/limits; the id in `agent.<role>.model`
> is what's actually requested. Change it if TechNL exposes Opus under a
> different id.

## The escalation ladder + capped loops

Encoded in `lead.md`'s prompt as **hard ceilings**:

```
per task:   sonnet ×3   →   opus ×1   →   FAILED (recompute deps, move on)
            task_retry_sonnet=3   task_retry_opus=1

loops:      plan_review_rounds      = 3   (plan ↔ reviewer)
            checklist_review_rounds = 2   (phase design ↔ reviewer)
            review_rounds           = 5   (closer's gate fix-loop)
```

Enforcement is **hybrid**: the `lead` drives the flow and self-polices the caps
interactively, and the Opus escalation attempt is taken by the lead itself
(it runs on Opus). This part is *soft* — prompt-driven, not mechanically
enforced. See [Phase 2](#phase-2--deferred) for the deterministic version.

## How to use it

The full flow, driven from `lead`:

1. Launch your lane (`oc-personal` / `oc-work`) and **Tab to the `lead`** agent
   (it's the only `primary` role; it shows in the switcher).
2. Give it a feature/spec. It will:
   1. **Plan** — dispatch `planner` (or you run `/plan <spec>`), then plan-review
      with `reviewer` (fix-loop up to `plan_review_rounds`).
   2. **Per phase** — dispatch `architect` for the design, checklist-review it
      with `reviewer` (up to `checklist_review_rounds`).
   3. **Per task** — dispatch `developer` under the escalation ladder; on success
      it commits.
   4. **Close** — `/close` (or dispatch `closer`): run the gate, fix-loop up to
      `review_rounds`, then advance with a handoff or block with a reason.
3. Repeat until all phases close; the lead summarises what shipped and what FAILED.

You don't have to run the whole machine — the commands are useful standalone:
`/plan` for a phased plan, `/review` as a release gate on your current diff,
`/close` to wrap a chunk of work. The subagents (`planner`/`architect`/… ) are
also directly callable with `@name`.

### A quick smoke test

```
oc-work        # or oc-personal
# Tab to `lead`, then:
build a tiny slugify() helper with a test
# watch: plan → @developer edits + tests + commits → /review → /close
```

## Verifying which model an agent actually used  ⚠️ gotcha

**The footer only shows the foreground *primary* agent's model.** A subagent
invoked via `@name` (or a command's `subtask`) runs as a **child** — the footer
keeps showing whatever primary you were on and never switches to the child. So
"the footer says Sonnet while `@planner` runs" does **not** mean planner ran on
Sonnet. Don't trust the footer for subagents.

The ground truth is the log — every stream records the agent, its mode, and the
real model:

```bash
grep 'agent=planner' ~/.local/share/opencode/log/opencode.log | tail -3
# → ... providerID=technl modelID=claude-opus-4-8 ... agent=planner mode=subagent
```

Swap `planner` for any role. This is the reliable way to confirm both the
**tier** (opus vs sonnet) and, under `oc-work`, the **provider** (`technl`, not
`anthropic` — the isolation check). Subagents carry their *own* configured
model, independent of the parent, so this is per-agent accurate.

## Where everything lives

| Piece | Path |
|---|---|
| Role prompts (model-less) | `system/opencode/agent/{lead,planner,architect,developer,reviewer,closer}.md` |
| Slash commands | `system/opencode/command/{plan,review,close}.md` |
| Command deployment | [`nix/home/opencode.nix`](../nix/home/opencode.nix) (`opencode/command` source) |
| Per-lane model tiers | [`nix/home/codemem.nix`](../nix/home/codemem.nix) (`agent.<role>.model` + the Opus `models` entry in each `opencode.json`) |
| Runtime log (verification) | `~/.local/share/opencode/log/opencode.log` |

## Extending it

- **Add a role:** drop a model-less `system/opencode/agent/<role>.md`, `git add`,
  rebuild. It inherits the lane's Sonnet default automatically. To put it on
  Opus, add `agent.<role>.model` to **both** `opencode.json`s in `codemem.nix`
  (personal → `anthropic/…`, work → `technl/…`).
- **Change a role's tier:** edit its `agent.<role>.model` in `codemem.nix` (both
  lanes). Remove the entry to drop it back to the Sonnet default.
- **New client lane:** a new lane (see
  [client tooling → onboard](opencode-client-tooling.md#runbook--onboard-a-new-client))
  inherits these global roles for free. Mirror the `agent.<role>.model` Opus
  pins into the new lane's `opencode.json`, pointing at *its* provider — never
  leave `lead`/`planner` unset there, or they'll fall back to the base config's
  `anthropic/*`.
- **Add a command:** drop `system/opencode/command/<name>.md` (frontmatter:
  `description`, `agent`, optional `subtask: true`/`model`; body is the prompt,
  `$ARGUMENTS` is substituted), `git add`, rebuild.

## Phase 2 — deferred

The current escalation enforcement is soft (the lead self-polices its caps). The
deterministic version, not yet built:

- **`flow-task`** — a headless runner (`opencode run --agent developer --model
  <tier>`) that *enforces* the retry caps and does the real per-attempt
  sonnet→opus model swap, gating on build/test signal between attempts.
- **`flow-commit`** — a focused commit helper (the schema's `sb-commit.sh`
  equivalent).

Both would ship like [`oc-tooling`](opencode-client-tooling.md) — a
`writeShellScriptBin` in `nix/home/opencode.nix` from a script in
`system/opencode/bin/`.
