# Global instructions (personal baseline)

These rules apply to **every** OpenCode session (both `oc-personal` and
`oc-work`). They are the global layer; project-root `AGENTS.md` files and the
per-client overlay (e.g. `ahold.md`, loaded only under `oc-work`) stack on top.

## Working style

- Verify premises against real source before acting; don't assume. If something
  is unverified, say so plainly rather than presenting a guess as fact.
- Don't give up early. When a first approach fails, dig into the actual cause.
- When you have enough to act, act — don't narrate options you won't take.
- Report outcomes honestly: if a step was skipped or a test failed, say so.

## Code

- Match the surrounding code: its naming, structure, comment density, and idiom.
  Read neighbouring files before adding new patterns.
- Prefer the smallest change that solves the problem. Don't refactor unrelated
  code in passing.
- No secrets in files — API keys, tokens, internal hostnames, private
  identifiers. Secrets are resolved at runtime (e.g. `pass-cli`), never written.

## Environment

- This machine is managed declaratively via **nix-darwin / home-manager**
  (`~/.dotfiles`). Prefer declarative Nix modules over imperative install
  commands. Flakes only see git-tracked files — `git add` new files before a
  rebuild.
- Default toolchain assumptions: Node via nvm, Java via jenv, Kubernetes via
  kubectl. Python is **not** centrally managed (no pyenv).

## Privacy

- Strong self-hosting / privacy bent: prefer fully-local or sanctioned-channel
  paths over sending data to third-party providers. When a task could exfiltrate
  data to an external service, flag it before doing it.
