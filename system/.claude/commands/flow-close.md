---
description: Close the current phase — gate it, decide advance/block, write a handoff (reviewer + closer subagents).
argument-hint: [phase or notes]
---

Close the current phase:

1. Dispatch the `reviewer` subagent on the phase's changes as a release gate.
2. Dispatch the `closer` subagent with the reviewer's verdict. It confirms the
   tasks are committed and green, then either advances with a handoff or
   blocks with the reason.

Report the closer's recommendation and handoff.

$ARGUMENTS
