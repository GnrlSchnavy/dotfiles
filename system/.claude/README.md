# Claude Code Configuration

Version-controlled Claude Code settings for the **personal lane**,
symlinked into `~/.claude/` by home-manager (see
[`nix/home/files.nix`](../../nix/home/files.nix) and
[`nix/home/claude-lanes.nix`](../../nix/home/claude-lanes.nix)).
The work lane (`cc-work`, `~/.claude-work/`) shares the agents and
commands from here — see [below](#work-lane-claude-work).

## Contents

| Path | Managed how | Purpose |
|---|---|---|
| `settings.local.json` | symlink → `~/.claude/settings.local.json` | Active permissions and tool access |
| `settings.template.json` | symlink → `~/.claude/settings.template.json` | Starter template for new machines |
| `README.md` | symlink → `~/.claude/README.md` | This file |
| `CLAUDE.md` | symlink → `~/.claude/CLAUDE.md` | Global baseline instructions (both lanes) |
| `agents/` | symlink → `~/.claude/agents` (read-only dir) | Custom subagent definitions (both lanes) |
| `commands/` | symlink → `~/.claude/commands` (read-only dir) | Custom slash commands, incl. `/flow*` (both lanes) |
| `skills/` | symlink → `~/.claude/skills` (read-only dir) | Custom skills (vault-* etc.), personal lane only |
| `hooks/` | symlink → `~/.claude/hooks` (read-only dir) | `work-lane-guard.sh` + `.jq` — blocks client work trees in the personal lane |
| `settings.json` | **NOT symlinked** — reference snapshot | Seeded to `~/.claude/settings.json` by `setup.sh` only when absent; owned keys merged on every rebuild |

`../.claude-mem/settings.json` is the same kind of reference snapshot
for claude-mem, seeded to `~/.claude-mem/settings.json` by `setup.sh`
(with absolute home paths rewritten for the current user).

## Why settings.json is not symlinked

Claude Code rewrites `~/.claude/settings.json` at runtime (plugin
toggles, effort level, survey state). A read-only Nix-store symlink
breaks the app's atomic rename — the same failure mode as
`~/.docker/config.json`. So the file is owned by the app.

It is no longer *only* seeded, though: on every rebuild the
`claudeLaneSettings` activation step in `claude-lanes.nix` merges the
keys the lane module owns into it —

- `env` — the lane's codemem env and `CC_WORK_ROOTS` (other env keys kept);
- `permissions.deny` — `Read`/`Edit` rules for each client work root
  (added when missing; your own rules kept);
- `sandbox` — the Bash sandbox, on, with each work root unreadable and no
  unsandboxed retries; the build caches/registries it allows are appended
  to your own lists;
- `hooks` — entries whose command lives under `~/.claude/hooks/` are
  replaced; plugin and hand-added hooks are kept.

The merge is idempotent and leaves plugins, your own permission rules and
every other key alone. So: change owned keys in `claude-lanes.nix`, everything else
in the app.

To re-seed manually (then rebuild to re-merge the owned keys):

```bash
cp ~/.dotfiles/system/.claude/settings.json ~/.claude/settings.json
```

On a fresh machine the merge itself starts from this snapshot when
`~/.claude/settings.json` doesn't exist yet, so no manual step is needed.

Everything else under `~/.claude/` (transcripts, plugin caches,
session state) is untouched by home-manager.

## Work lane (`~/.claude-work`)

The work lane is a separate config dir, used only through `cc-work`
(Ahold, via the TechNL gateway — `cc-work` wraps DevAI CLI's `devai-claude`).
Declared in `claude-lanes.nix`:

| Path | Source |
|---|---|
| `~/.claude-work/CLAUDE.md` | this `CLAUDE.md` + every `../.claude-work/ahold/*.md`, concatenated |
| `~/.claude-work/agents`, `commands` | `agents/`, `commands/` here (shared) |
| `~/.claude-work/hooks` | `../.claude-work/hooks/` (`lane-check.sh`, `agents-md.sh`) |
| `~/.claude-work/settings.json` | app-owned; env, hooks, `skipWebFetchPreflight`, default model `opus` merged on rebuild |

No `skills/` there — the vault-* skills read the personal Obsidian
vault. Full details: [`docs/claude-code.md`](../../docs/claude-code.md#two-claude-code-lanes).

## Editing settings

```bash
$EDITOR ~/.dotfiles/system/.claude/settings.local.json

# Apply (rebuild reads the new content and updates the symlink target)
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
```

Changes are tracked in git automatically since the files live inside
the dotfiles repo. The `agents/`, `commands/`, `skills/` and `hooks/`
directories are symlinked whole — add or edit a file here, `git add`,
rebuild, and it appears under `~/.claude/` (and, for agents/commands,
`~/.claude-work/`).

## New-machine setup

`setup.sh` runs `darwin-rebuild switch` (creates the symlinks and
merges the owned settings keys) and then seeds the non-symlinkable
settings files if they don't exist yet (see the fresh-machine note
above). After that, run `cc-lanes-setup` once to install the codemem
plugin into both lanes.
