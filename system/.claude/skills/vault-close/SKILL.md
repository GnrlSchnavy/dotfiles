---
name: vault-close
description: End of day processing — extracts action items from today, surfaces vault connections, identifies carry-forward items, and suggests what to link.
allowed-tools: Bash Read Glob Grep
---

# End of Day Review — /vault-close

You are helping me close out the day. Review what happened, extract what matters, and prepare for tomorrow.

## Vault Location
`/Users/yvan/Documents/Obsidian/Yvan_claude`

## Instructions

### Step 1: Read today's daily note
Find today's note in `06 - Daily/YYYYMMDD.md`. If it doesn't exist or is empty, note that.

### Step 2: Extract action items
From today's note and any notes modified today:
- List completed tasks (`- [x]`)
- List remaining open tasks (`- [ ]`)
- Identify any implicit action items from journal text (things mentioned but not tasked)

### Step 3: Surface vault connections
Look at the topics, people, and projects mentioned today. Search the vault for related notes that aren't currently linked. Suggest `[[wikilinks]]` that should be added.

### Step 4: Check for orphaned ideas
Scan today's writing for ideas, insights, or thoughts that deserve their own note but are currently buried in the daily entry. Flag these as candidates for `/vault-graduate`.

### Step 5: Present the close-out
Structure your output as:

**Today's summary** — What I worked on / thought about
**Completed** — Tasks and milestones finished
**Carry forward** — Open items for tomorrow
**Connection suggestions** — Notes that should be linked together
**Graduate candidates** — Ideas worth extracting into standalone notes
**Reflection prompt** — One question to think about based on today's patterns

## Rules
- Do NOT modify any files
- Content may be in Dutch or English
- Present output in English
- This is meant to be quick — keep it scannable
