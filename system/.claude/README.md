# Claude Code Configuration

Version-controlled Claude Code settings, linked into `~/.claude/` by
home-manager on every machine (see
[`nix/home/claude-code.nix`](../../nix/home/claude-code.nix)). What the
setup talks to — Claude Max on the personal Mac, the DevAI/TechNL
gateway on the work Mac — comes from the host's profile
([`nix/profiles/`](../../nix/profiles/README.md)).

## Contents

| Path | Managed how | Purpose |
|---|---|---|
| `README.md` | symlink → `~/.claude/README.md` | This file |
| `CLAUDE.md` | → `~/.claude/CLAUDE.md`, with the profile's overlay appended | Global baseline instructions |
| `agents/` | symlink → `~/.claude/agents` (read-only dir) | Custom subagent definitions |
| `commands/` | symlink → `~/.claude/commands` (read-only dir) | Custom slash commands, incl. `/flow*` |
| `skills/` | → `~/.claude/skills`, vault path filled in (personal profile only) | Custom skills (vault-* etc.) |
| `settings.json` | **NOT symlinked** — reference snapshot | Creates `~/.claude/settings.json` when absent; owned keys merged on every rebuild |

On the work Mac, `~/.claude/hooks` comes from
[`../claude-work/hooks/`](../claude-work/hooks/) (`gateway-check.sh`,
`agents-md.sh`) and the Ahold overlay
([`../claude-work/ahold/`](../claude-work/ahold/)) is appended to
`CLAUDE.md`. Full details:
[`docs/claude-code.md`](../../docs/claude-code.md#work-profile).

## Why settings.json is not symlinked

Claude Code rewrites `~/.claude/settings.json` at runtime (plugin
toggles, effort level, survey state). A read-only Nix-store symlink
breaks the app's atomic rename — the same failure mode as
`~/.docker/config.json`. So the file is owned by the app.

On every rebuild the `claudeSettings` activation step in
`claude-code.nix` merges the keys the profiles own
(`dotfiles.claude.settings`) into it — `env` (overwritten; keys no
longer owned are removed), `union` lists such as the sandbox paths
(missing entries appended), `hooks` under `~/.claude/hooks/` (replaced),
`default` (only where absent) and `set` (always written: plugins,
sandbox flags). Plugins, your own permission rules and every other key
are left alone. So: change owned keys in the profile's `claude.nix`,
everything else in the app. Details:
[`docs/claude-code.md`](../../docs/claude-code.md#settings-merge).

To re-seed manually (then rebuild to re-merge the owned keys):

```bash
cp ~/.dotfiles/system/.claude/settings.json ~/.claude/settings.json
```

On a fresh machine the merge itself starts from this snapshot when
`~/.claude/settings.json` doesn't exist yet, so no manual step is needed.

Everything else under `~/.claude/` (transcripts, plugin caches,
session state) is untouched by home-manager.

## Editing settings

Settings you want on every machine of a role and kept in sync go into
the owned keys in `nix/profiles/<role>/claude.nix`; anything else, set
in the app (`/config`, `/permissions`), which writes
`~/.claude/settings.json`. Claude Code never reads a
`settings.local.json` in the user config dir — that name is only a
project's `.claude/settings.local.json`, where "don't ask again"
approvals land.

The `agents/`, `commands/` and `skills/` directories are linked whole —
add or edit a file here, `git add`, rebuild, and it appears under
`~/.claude/`.

## New-machine setup

`setup.sh` runs `darwin-rebuild switch`, which creates the symlinks and
the settings file (from the snapshot, with the owned keys merged in).
The plugins are among those owned keys (`enabledPlugins`,
`extraKnownMarketplaces`), so the first interactive session fetches them,
codemem included; `codemem-setup` installs codemem right away if only
`claude -p` has run so far.
