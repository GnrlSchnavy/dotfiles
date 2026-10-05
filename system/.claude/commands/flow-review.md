---
description: Gate-review the current changes (or a named target) — PASS/BLOCK (reviewer subagent).
argument-hint: [target]
---

Dispatch the `reviewer` subagent as a release gate and return its PASS/BLOCK
verdict with severity-ranked findings. Default scope is the current uncommitted
+ recent changes (`git diff`, `git diff --staged`, `git log`), unless a target
is named below.

$ARGUMENTS
