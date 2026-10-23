# Ahold overlay — stack & conventions

<!-- This repo is public: keep this overlay to what's generic. Client-specific
     build commands, test gates, PR conventions and compliance notes belong in
     the private client tooling repo, as CLAUDE.md / AGENTS.md files that
     cc-tooling links into each checkout (docs/client-tooling.md). Every *.md
     in this folder is loaded on the work machine. -->

- Primary stack: Java / Spring Boot (services), Angular (front-end), Kubernetes
  for deployment.
- Follow the existing module/package structure and naming already in the repo
  over any generic convention.
- Repo-specific build commands, test gates and PR conventions come from the
  checkout's own `CLAUDE.md` / `AGENTS.md` (linked by `cc-tooling`); follow
  those over anything here.
