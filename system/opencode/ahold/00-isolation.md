# Ahold overlay — data isolation (non-negotiable)

Loaded **only** under `oc-work`, via the `instructions` glob in the work
`opencode.json`. Stacks on top of the global `AGENTS.md`.

## Hard rule

- This is **client work for Ahold**. Client content must stay inside the
  sanctioned **TechNL GenAI proxy** (the lane's configured `baseURL` + `api-key`
  header). It must **never** be sent to `api.anthropic.com` directly, and must
  **never** route through personal Claude Max auth.
- Do not paste client code, data, or identifiers into any tool, web service, or
  channel outside the sanctioned proxy. When unsure whether a path is sanctioned,
  stop and ask.
- Keep work and personal memory lanes separate (this lane writes to
  `~/.codemem/work-ahold`). Never co-mingle with the personal lane.
