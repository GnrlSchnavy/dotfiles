---
description: Drive a feature from spec to done as the lead — plan, design, implement, gate, close — by dispatching the planner/architect/developer/reviewer/closer subagents.
argument-hint: <spec or feature request>
---

For this feature you are the **lead**. You drive it from spec to done by
delegating to the role subagents and specialists — you do as little hands-on
editing as possible. Your job is decomposition, dispatch, and gatekeeping.

Feature / spec:

$ARGUMENTS

## Roles you dispatch (Agent tool, by subagent name)

- `planner`   — spec → dependency-ordered tasks grouped into phases (+ acceptance criteria). Opus tier.
- `architect` — per-phase design + acceptance criteria, before any code in that phase.
- `developer` — implements ONE task: code + tests + a focused commit. Sonnet tier.
- `reviewer`  — reviews a plan (plan-review) or finished changes (gate). Read-only, PASS/BLOCK.
- `closer`    — closes a phase: checks tests + the gate verdict, decides advance/block, writes a handoff.

Subagents cannot dispatch other subagents, so specialist craft is yours to
route: when a task needs deep domain expertise, dispatch the specialist
(`typescript-pro`, `java-architect`, `spring-boot-engineer`, `kotlin-specialist`,
`react-specialist`, `sql-pro`, `test-automator`, `code-reviewer`,
`architect-reviewer`, …) directly instead of `developer`/`reviewer`.

## Scale effort to the task (token discipline)

**Triage first; don't run the full machine on small work.** Every dispatch
starts a fresh context, so it has real token cost:

- **Trivial change** (a one-liner, a rename, an obvious fix): just do it
  yourself. No planner, no architect, no gate.
- **Small task** (one file, clear scope): dispatch `developer` directly and do a
  single `reviewer` pass. Skip planner/architect.
- **Substantial feature** (multi-file, real design risk): run the full flow.

The capped loops are **ceilings, not targets** — default to *one* review round
and loop again only when the reviewer returns Critical/Major findings.

## Flow (substantial features)

1. **Plan.** Dispatch `planner`. Plan-review with `reviewer`, fix-loop up to
   `plan_review_rounds`. Don't build on an unreviewed plan.
2. **Per phase:** dispatch `architect` for the design + acceptance criteria;
   checklist-review the design with `reviewer`, up to `checklist_review_rounds`.
3. **Per task in the phase:** dispatch `developer`, running the escalation
   ladder below. On success the developer commits.
4. **Close the phase:** dispatch `reviewer` on the phase's changes (fix-loop
   with `developer` up to `review_rounds`), then dispatch `closer` with the
   final verdict. Only advance when the gate PASSes. If a task ended FAILED,
   recompute which remaining tasks depended on it and re-plan those.
5. Repeat until all phases close. Summarise what shipped and what FAILED.

## Escalation ladder (per task) — HARD CAPS

- `task_retry_sonnet = 3` → `developer` (sonnet tier), up to 3 attempts.
- `task_retry_opus   = 1` → if still failing, escalate ONE attempt at the opus
  tier: dispatch `developer` with the model overridden to `opus`.
- Still failing → mark the task **FAILED**, recompute deps, move on. Never
  silently loop past these caps.

## Capped loops (hard ceilings)

- `plan_review_rounds      = 3`  (plan ↔ `reviewer`)
- `checklist_review_rounds = 2`  (phase design ↔ `reviewer`)
- `review_rounds           = 5`  (phase gate fix-loop)

Announce when a cap is hit instead of exceeding it.

## Rules

- A task isn't done until its tests pass **and** it's committed. Gate on real
  signal (build/test output), not optimism.
- One task = one focused commit, in the project's commit convention.
- Tiers are the aliases `opus` / `sonnet` only — never a full provider model
  id. Each lane maps the aliases to its own sanctioned endpoint.
- Report honestly: surface FAILED tasks and skipped steps; don't paper over them.
