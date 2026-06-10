# Claude Code Configuration

Version-controlled Claude Code settings, symlinked into `~/.claude/`
by home-manager (see [`nix/home/files.nix`](../../nix/home/files.nix)).

## Contents

| Path | Managed how | Purpose |
|---|---|---|
| `settings.local.json` | symlink → `~/.claude/settings.local.json` | Active permissions and tool access |
| `settings.template.json` | symlink → `~/.claude/settings.template.json` | Starter template for new machines |
| `README.md` | symlink → `~/.claude/README.md` | This file |
| `agents/` | symlink → `~/.claude/agents` (read-only dir) | Custom subagent definitions |
| `commands/` | symlink → `~/.claude/commands` (read-only dir) | Custom slash commands |
| `skills/` | symlink → `~/.claude/skills` (read-only dir) | Custom skills (vault-* etc.) |
| `settings.json` | **NOT symlinked** — reference snapshot | Seeded to `~/.claude/settings.json` by `setup.sh` only when absent |

`../.claude-mem/settings.json` is the same kind of reference snapshot
for claude-mem, seeded to `~/.claude-mem/settings.json` by `setup.sh`
(with absolute home paths rewritten for the current user).

## Why settings.json is not symlinked

Claude Code rewrites `~/.claude/settings.json` at runtime (plugin
toggles, effort level, survey state). A read-only Nix-store symlink
breaks the app's atomic rename — the same failure mode as
`~/.docker/config.json`. So home-manager owns only the static files
above; the rewritten ones are seeded once and then owned by the app.

To re-seed manually:

```bash
cp ~/.dotfiles/system/.claude/settings.json ~/.claude/settings.json
```

Everything else under `~/.claude/` (transcripts, plugin caches,
session state) is untouched by home-manager.

## Editing settings

```bash
$EDITOR ~/.dotfiles/system/.claude/settings.local.json

# Apply (rebuild reads the new content and updates the symlink target)
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
```

Changes are tracked in git automatically since the files live inside
the dotfiles repo. The `agents/`, `commands/` and `skills/` directories
are symlinked whole — add or edit a file here, rebuild, and it appears
under `~/.claude/`.

## New-machine setup

No separate step. `setup.sh` runs `darwin-rebuild switch` (creates the
symlinks via home-manager) and then seeds the two non-symlinkable
settings files if they don't exist yet.
