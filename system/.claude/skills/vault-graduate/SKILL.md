---
name: vault-graduate
description: Extract ideas, insights, and original thinking from daily notes and promote them into standalone notes in the vault.
allowed-tools: Bash Read Write Glob Grep
---

# Idea Graduation — /vault-graduate

Scan daily notes for ideas, insights, and original thinking that deserve their own standalone note. Present candidates for promotion, and create notes for the ones I approve.

## Vault Location
`/Users/yvan/Documents/Obsidian/Yvan_claude`

## Instructions

### Step 1: Scan recent daily notes
Read daily notes from the last 30 days in `06 - Daily/`. Skip empty templates. Look for:
- Original ideas or insights (not just task lists)
- Opinions or reflections that could become standalone notes
- Recurring themes that keep appearing but don't have a dedicated note
- References to concepts that don't have their own note yet
- Interesting observations, patterns, or realizations

### Step 2: Cross-reference with existing vault
For each candidate, check:
- Does a note for this topic already exist?
- Which MOC or area would it belong to?
- What existing notes should it link to?

### Step 3: Present candidates
For each candidate idea, present:
- **The idea** — What it is, in one sentence
- **Source** — Which daily note(s) it came from, with relevant quotes
- **Proposed location** — Where in the vault it should live (folder + filename)
- **Proposed connections** — Which existing notes it should `[[link]]` to
- **Status** — How developed is it? (seed, growing, ready to crystallize)

### Step 4: Wait for approval
Present all candidates and ask which ones I want to graduate. For each approved idea, create the note.

### Step 5: Create graduated notes
For approved ideas, create a note with this structure:
```markdown
---
date: YYYY-MM-DDTHH:MM
tags:
  - graduated
---

# [Idea Title]

[Core claim or question]

## Context
Originated from daily note [[YYYYMMDD]]. [Brief context of how this idea emerged.]

## Development
[The idea expanded — what it means, why it matters, open questions]

## Connections
- [[Related note 1]]
- [[Related note 2]]
```

Place in the appropriate folder:
- New project idea → `01 - Projects/`
- Ongoing area insight → `02 - Areas/`
- Quick thought worth keeping → `05 - Fleeting/`
- Reference material → `03 - Resources/`

## Rules
- Do NOT modify existing files — only create NEW files
- Always present candidates and wait for approval before creating
- Graduated notes should capture the CORE of the idea, not be exhaustive
- Use `[[wikilinks]]` to connect to existing notes
- Content may be in Dutch or English — match the language of the source material
