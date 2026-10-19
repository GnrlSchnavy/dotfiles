# Ahold overlay — data isolation (non-negotiable)

Loaded **only** on the work machine (profile `work`, sessions started with
`cc-work`) — home-manager appends every file in this folder to the global
`CLAUDE.md`. Stacks on top of the global baseline.

## Hard rule

- This is **client work for Ahold**. Client content must stay inside the
  sanctioned **TechNL GenAI gateway** (reached through DevAI CLI, which sets
  `ANTHROPIC_BASE_URL` and handles auth). It must **never** be sent to
  `api.anthropic.com` directly, and must **never** route through personal
  Claude Max auth.
- Do not paste client code, data, or identifiers into any tool, web service, or
  channel outside the sanctioned proxy. That includes WebFetch/WebSearch to
  third-party sites with client content in the query. When unsure whether a
  path is sanctioned, stop and ask.
- Memory stays on this machine (`~/.codemem/work`), extracted through the same
  gateway. Never copy it to a personal machine.

## Repo instructions

- Ahold repos carry `AGENTS.md` files (the team's convention). The repo-root
  `AGENTS.md` is injected at session start; before working inside a
  subdirectory, also read any `AGENTS.md` in that directory and its parents
  within the repo, and follow them.
