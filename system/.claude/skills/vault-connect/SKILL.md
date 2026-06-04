---
name: vault-connect
description: Take two domains or concepts and connect them using the vault's content and link graph — find unexpected bridges between them.
argument-hint: <domain1> <domain2>
allowed-tools: Bash Read Glob Grep
---

# Concept Connector — /vault-connect

Take two seemingly unrelated domains or concepts and find bridges between them using my vault content.

## Vault Location
`/Users/yvan/Documents/Obsidian/Yvan_claude`

## Domains to Connect
$ARGUMENTS

Parse the two domains from the arguments (e.g., "cooking homelab" means Domain A = cooking, Domain B = homelab).

## Instructions

### Step 1: Map Domain A
Find all notes related to the first domain:
- Search file names, folder names, and content
- Read relevant notes in full
- Map the `[[wikilinks]]` neighborhood — what does this domain connect to?
- Note the key concepts, principles, and patterns within this domain

### Step 2: Map Domain B
Do the same for the second domain.

### Step 3: Find bridge notes
Look for notes that are linked to (or mention) BOTH domains. These are the natural bridges. Also look for:
- Notes in one domain that use language or patterns common in the other
- People mentioned in both domains
- Timestamps where activity in both domains coincided
- Shared tags, MOC connections, or common linked notes

### Step 4: Generate novel connections
Even where no explicit bridge exists, look for:
- **Structural parallels** — similar patterns, workflows, or approaches used in both
- **Transferable principles** — a lesson from one domain that applies to the other
- **Creative synthesis** — a new idea that only emerges when you combine both domains
- **Skill transfers** — capabilities from one domain useful in the other

### Step 5: Present the connections
Structure as:

**Domain A: [name]** — Summary of vault content
**Domain B: [name]** — Summary of vault content

**Natural bridges** — Notes/concepts that already connect these domains

**Bridge 1: [name]**
- Evidence from vault
- The connection explained

**Bridge 2: [name]**
...

**Novel connections** — New ideas that emerge from combining these domains
**Synthesis idea** — The single most interesting idea that only exists at the intersection

## Rules
- Do NOT modify any files
- Connections should be genuine and insightful, not forced
- Reference specific vault content as evidence
- Content may be in Dutch or English
