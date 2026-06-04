---
name: vault-context
description: Load full context about my life, work, and current state from my Obsidian vault. Reads context files, daily notes, MOCs, and follows backlinks to build a complete picture.
allowed-tools: Bash Read Glob Grep
---

# Vault Context Loader

You are loading the full context of my Obsidian vault to understand who I am, what I'm working on, and where I currently am in life and work.

## Vault Location
`/Users/yvan/Documents/Obsidian/Yvan_claude`

## Vault Structure
```
00 - Maps of Content/    # MOCs — top-level navigation
01 - Projects/           # Active projects
02 - Areas/              # Ongoing areas of responsibility
03 - Resources/          # Reference material
04 - Permanent/          # Permanent/evergreen notes
05 - Fleeting/           # Quick captures
06 - Daily/              # Daily notes (YYYYMMDD.md)
07 - Archives/           # Archived/completed projects
99 - Meta/               # Templates, images, JS
```

## Instructions

### Step 1: Read all Maps of Content
Read every file in `00 - Maps of Content/`. These are the high-level structure of my thinking. Pay attention to the `[[wikilinks]]` — they reveal what's connected.

### Step 2: Read recent daily notes
Read the last 7 daily notes from `06 - Daily/` (sorted by date descending). Skip notes that are just empty templates (contain "Customize this template to your liking!"). Focus on notes with actual journal entries or tasks.

### Step 3: Read active projects
Read all files in `01 - Projects/` (including subdirectories). These are what I'm currently working on.

### Step 4: Scan areas and fleeting notes
Read files in `02 - Areas/` and `05 - Fleeting/` to understand my ongoing interests and recent quick captures.

### Step 5: Follow backlinks
From all the `[[wikilinks]]` you've encountered, identify the most-referenced notes and read those too. This reveals the core concepts in my thinking.

If the Obsidian CLI is available (`obsidian` command), use:
- `obsidian backlinks "<note>"` to find connections
- `obsidian orphans` to find isolated notes
- `obsidian tags` to see tag distribution

Otherwise, parse `[[wikilinks]]` from file contents manually using grep.

### Step 6: Synthesize
Present a structured summary:
1. **Who I am** — based on personal notes, daily entries, areas of interest
2. **What I'm working on** — active projects, their current status
3. **What I'm thinking about** — themes from daily notes, MOC connections
4. **Key relationships** — people and entities mentioned across notes
5. **Current state** — what the most recent notes suggest about where I am right now

## Rules
- Do NOT modify any files in the vault
- Content may be in Dutch or English — handle both naturally
- Present your output in English unless I ask otherwise
- This is a READ-ONLY operation — just build understanding and report
