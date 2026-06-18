---
description: Gate-review the current changes (or a named target) — PASS/BLOCK.
agent: reviewer
subtask: true
---
Review as a release gate and return a PASS/BLOCK verdict with severity-ranked
findings. Default scope is the current uncommitted + recent changes (use
`git diff`, `git diff --staged`, `git log`), unless a target is named below.

$ARGUMENTS
