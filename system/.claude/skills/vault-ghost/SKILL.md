---
name: vault-ghost
description: Answer a question the way I would — builds a voice profile from the vault, writes in my voice, then evaluates fidelity.
argument-hint: <question>
allowed-tools: Bash Read Glob Grep
---

# Ghost Writer — /vault-ghost

You will answer a question the way I would, based on my writing in the Obsidian vault. This is not about what you think — it's about channeling what I think.

## Vault Location
`/Users/yvan/Documents/Obsidian/Yvan_claude`

## The Question
$ARGUMENTS

## Instructions

### Step 1: Build a voice profile
Scan the vault broadly — daily notes, project files, fleeting notes, areas. Pay attention to:
- How I structure my thoughts (lists vs prose, short vs long)
- My vocabulary and phrasing patterns
- Whether I write in Dutch, English, or mix
- My tone (formal vs casual, confident vs exploratory)
- Recurring themes and concerns
- How I express opinions and uncertainty

### Step 2: Find relevant vault content
Search the vault for notes related to the question topic. Read those notes carefully to understand my existing perspective.

### Step 3: Answer the question in my voice
Write the answer as I would — same tone, same patterns, same level of detail. If I tend to be direct, be direct. If I tend to hedge, hedge. Match the language I typically use for this domain.

### Step 4: Evaluate fidelity
After writing the answer, add a section called **Fidelity Check** where you:
- Rate how confident you are this matches my voice (1-10)
- Note what vault evidence supports this answer
- Flag where you had to fill gaps (things I haven't written about)
- Identify where my actual answer might differ

## Rules
- Do NOT modify any files
- The answer should feel like it came from me, not from an AI
- If there's not enough vault content to form a view, say so honestly
- Use whichever language feels most natural for the topic based on my patterns
