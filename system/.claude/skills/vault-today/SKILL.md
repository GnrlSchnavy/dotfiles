---
name: vault-today
description: Morning review — reads recent daily notes, open tasks, and active projects to create a prioritized plan for the day. Creates today's daily note if it doesn't exist.
allowed-tools: Bash Read Write Glob Grep
---

# Morning Review — /vault-today

You are my morning planning partner. Help me start the day with clarity by reviewing what's recent, what's pending, and what matters most.

## Vault Location
`/Users/yvan/Documents/Obsidian/Yvan_claude`

## Instructions

### Step 1: Check today's daily note
Today's date format: `YYYYMMDD.md` in `06 - Daily/`.

If today's daily note doesn't exist, create it with this structure:
```markdown
---
date: YYYY-MM-DDTHH:MM
tags:
  - Daily
cssclasses:
  - daily
---
# DAILY NOTE
## <Day of week>, <Month> <Day>, <Year>
***
### Journal

***
### Tasks
- [ ]
```

### Step 2: Read recent daily notes
Read the last 7 daily notes (by filename date, descending). Skip notes that are empty templates. Extract:
- Journal entries and reflections
- Open tasks (`- [ ]`)
- Completed tasks (`- [x]`)
- Any mentioned plans, deadlines, or commitments

### Step 3: Scan active projects
Read files in `01 - Projects/` for any recent updates, deadlines, or pending items.

### Step 4: Check fleeting notes
Read recent files in `05 - Fleeting/` — these may contain quick ideas or reminders that haven't been processed yet.

### Step 5: Present the morning review
Structure your output as:

**Continuity** — What was I working on yesterday / this week?
**Open loops** — Uncompleted tasks and unfinished threads
**Active projects pulse** — Quick status of each active project
**Suggested focus** — What you recommend I prioritize today, based on momentum, urgency, and vault patterns
**Unprocessed captures** — Any fleeting notes that should be dealt with

## Rules
- Only CREATE today's daily note if it doesn't exist — never modify existing notes
- Content may be in Dutch or English
- Present output in English
- Be concise but thorough — this is a quick morning briefing, not a deep analysis
