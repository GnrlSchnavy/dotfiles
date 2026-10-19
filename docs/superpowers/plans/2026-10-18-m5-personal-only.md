# One role per Mac: m5 personal, client Mac work

**Context:** from 2026-10-19 client work moves to a client-issued MacBook.
m5 becomes personal-only and gets a factory reset plus a fresh install; the
client Mac gets its own nix-darwin host with the work setup. Branch:
`personal-only`.

## Decisions (2026-10-18)

- Slack → personal (and also on the work Mac).
- Docker → Colima only, Docker Desktop dropped (both Macs).
- `github-copilot-app` → work; `opencode`, `openspec`, `~/.ssh/gitlab` → personal.
- Work Mac Claude Code → work-only (DevAI/TechNL in `~/.claude`), no personal lane.
- Work Mac apps → Outlook, Teams, Slack, Copilot + shared dev tooling (no personal apps).
- Work Mac hostname/username → placeholders until it arrives.

## Done (on the branch)

- [x] Git: personal identity is the default; dotfiles clones always commit as personal; work profile overrides.
- [x] `nix/profiles/{dev,personal,work}` — hosts list profiles; flake `hostModules` wires them.
- [x] Shared Claude Code/codemem plumbing with options (`dotfiles.claude.*`, `dotfiles.codemem.*`).
- [x] Removed: `~/.claude-work`, personal-lane guard, lane-variable isolation, `cc-personal`, separate codemem viewer ports, Docker Desktop + `dw`/`dp`, `development/.docker/config.json`.
- [x] `work` host (placeholders), CI mirrors m5 via profiles, template updated.
- [x] Tests: `tests/gateway-check.sh` (was the lane-check half of `tests/guard.sh`).
- [x] `.wrangler/` untracked + ignored.
- [x] Docs rewritten for the profile split; `nix/PACKAGE-STRATEGY.md` stub removed.
- [ ] `nix flake check --no-build` — can't run in the Claude sandbox; run it yourself.

## Before the factory reset of m5

- [ ] Client Mac working (repos cloned, DevAI working) — don't wipe m5 before.
- [ ] `~/projects/ahold/*` fully pushed; nothing in stashes.
- [ ] Back up what Nix doesn't recreate: `~/.ssh` (personal GitHub key, NAS key, gitlab key), Obsidian vault (if not synced), `~/projects/personal` unpushed work, codemem personal DB (`~/.codemem/personal`) if wanted, browser profiles, anything in Documents/Downloads.
- [ ] Merge or push the branch so `setup.sh` on the fresh m5 gets it.
- [ ] Proton Pass: archive/delete the `Ahold` vault once the client Mac no longer needs it from your account (the work profile still reads `pass://Ahold/TechNLGenAI/*`).

## Work Mac onboarding

1. Check what the client allows: admin rights for Nix + Homebrew, MDM restrictions, Zscaler (Nix fetches may need its CA).
2. `nix/hosts/work/default.nix`: replace `changeme` with `whoami`; set LocalHostName to `work` or rename the host to match.
3. `./setup.sh`, then `pass-cli login`, then `devai setup`; start Claude with `cc-work`.
4. `~/.ssh/config` on that Mac: github.com → work key (unmanaged).

## Improvements (2026-10-19)

- [x] Lock-screen text: email instead of the phone number (the number stays in git history).
- [x] CLI tools moved from brew to nixpkgs; remaining brews say why; CI smoke check updated.
- [x] `tests/docs.sh`: architecture map ↔ `nix/` drift check, both ways.
- [x] `docs/superpowers/` committed (this plan, the homelab SSO plan, the superseded revert plan).
