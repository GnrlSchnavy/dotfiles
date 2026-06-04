---
name: vault-trace
description: Track how an idea or concept has evolved over time across the vault — builds a chronological map of its development.
argument-hint: <concept to trace>
allowed-tools: Bash Read Glob Grep
---

# Idea Trace — /vault-trace

Track the evolution of a concept through my vault over time. Build a chronological map of how this idea appeared, developed, and connected to other ideas.

## Vault Location
`/Users/yvan/Documents/Obsidian/Yvan_claude`

## Concept to Trace
$ARGUMENTS

## Instructions

### Step 1: Build a vocabulary map
The concept might be referred to in different ways. Identify synonyms, related terms, and adjacent concepts. Search for all of these across the vault.

### Step 2: Find all mentions
Search the entire vault for mentions of the concept and related terms. For each mention, note:
- The file name and path
- The date (from frontmatter, filename, or context)
- The surrounding context (what was being discussed)
- What other concepts are linked nearby (`[[wikilinks]]`)

### Step 3: Order chronologically
Arrange all mentions by date. Build a timeline.

### Step 4: Identify phases
Group the timeline into phases based on shifts in how the concept is discussed:
- When did it first appear?
- When did my understanding change?
- What triggered shifts in thinking?
- When did it connect to new domains?
- Is it growing, stable, or fading in recent notes?

### Step 5: Follow the connections
For each phase, trace the `[[wikilinks]]` and connections. How did this concept's neighborhood in the vault change over time? What new notes linked to it? What old connections were abandoned?

### Step 6: Present the trace
Structure as:

**Concept: [name]**
**First appeared:** [date and context]
**Time span:** [duration]
**Total mentions:** [count across files]

**Phase 1: [Name]** (date range)
- Key notes and what they reveal
- Connections formed

**Phase 2: [Name]** (date range)
- How thinking shifted
- New connections

[...continue for each phase]

**Current state** — Where this concept sits today in my thinking
**Trajectory** — Where it appears to be heading
**Unresolved tensions** — Open questions or contradictions about this concept

## Rules
- Do NOT modify any files
- Be thorough — scan the entire vault, including archives
- Quote relevant passages to show the evolution
- Content may be in Dutch or English
