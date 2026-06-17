# Ahold client overlay

Loaded **only** under `oc-work` (via `instructions` in the work `opencode.json`).
Stacks on top of the global `AGENTS.md`. Everything here is Ahold-specific.

## Hard rule — data isolation (non-negotiable)

- This is **client work for Ahold**. Client content must stay inside the
  sanctioned **TechNL GenAI proxy** (`https://api-ai.digitaldev.nl/anthropic/v1`,
  `api-key` header). It must **never** be sent to `api.anthropic.com` directly,
  and must **never** route through personal Claude Max auth.
- Do not paste client code, data, or identifiers into any tool, web service, or
  channel outside the sanctioned proxy. When unsure whether a path is sanctioned,
  stop and ask.
- Keep work and personal memory lanes separate (this lane writes to
  `~/.codemem/work-ahold`). Never co-mingle with the personal lane.

## Stack & conventions

<!-- Fill in Ahold's actual conventions as they solidify. Seeded with the
     enterprise-Java defaults implied by the available agents; adjust to match
     the real codebase. -->

- Primary stack: Java / Spring Boot (services), Angular (front-end), Kubernetes
  for deployment.
- Follow the existing module/package structure and naming already in the repo
  over any generic convention.
- (TODO) Document Ahold-specific build commands, test gates, branch/PR
  conventions, and any required headers/compliance notes here.
