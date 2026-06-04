---
name: vault-ideas
description: Deep 30-day vault scan with cross-domain pattern detection and graph analysis to generate ideas across all domains — tools to build, things to write, conversations to have, systems to implement.
allowed-tools: Bash Read Glob Grep
---

# Idea Generation — /vault-ideas

Run a comprehensive analysis of my entire Obsidian vault to generate actionable ideas across all domains of my life and work.

## Vault Location
`/Users/yvan/Documents/Obsidian/Yvan_claude`

## Instructions

### Step 1: Gather vault structure and context
Read in parallel:
- All MOCs in `00 - Maps of Content/`
- All files in `01 - Projects/` (active projects)
- All files in `02 - Areas/` (ongoing areas)
- Recent daily notes from `06 - Daily/` (last 30 days)
- All fleeting notes in `05 - Fleeting/`
- Resource files in `03 - Resources/`

### Step 2: Analyze vault health
If Obsidian CLI is available:
- `obsidian orphans` — isolated notes
- `obsidian tags` — tag distribution
Otherwise, manually check:
- Files with no `[[wikilinks]]` pointing to them
- Tags usage across files
- Dead-end notes (have links out but nothing linking in)

### Step 3: Cross-domain pattern detection
Look across ALL domains for:
- Skills or knowledge that could transfer between areas (e.g., Java patterns applied to homelab, cooking principles applied to software)
- Gaps where two areas should be connected but aren't
- Themes that keep appearing in daily notes but don't have a dedicated project or area

### Step 4: Generate ideas in categories

**Tools to build** — Software, automations, scripts, or systems that would help based on patterns in the vault. Be specific about what it would do and why.

**Things to write** — Essays, blog posts, documentation, or notes that the vault is "asking for" — where enough thinking exists but hasn't been crystallized.

**Conversations to have** — Based on people mentioned in notes, projects in progress, and open questions, suggest specific conversations with specific people about specific topics.

**Systems to implement** — Workflows, habits, or organizational patterns that would improve how I work or think, based on friction points visible in the vault.

**Areas to explore** — Topics or domains that seem to interest me based on vault evidence but haven't gotten dedicated exploration.

**Commands to build** — New Claude Code slash commands that would help based on how I use the vault.

### Step 5: Prioritize
End with a **Top 5 high-impact, do-now** list — the most actionable items from all categories.

## Rules
- Do NOT modify any files
- Ideas should be SPECIFIC and ACTIONABLE, not generic
- Every idea must reference specific vault content as evidence
- This takes time — read thoroughly before generating ideas
- Content may be in Dutch or English
