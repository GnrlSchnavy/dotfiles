# Claude Code Configuration

Version-controlled Claude Code settings, symlinked into `~/.claude/`
by home-manager (see [`nix/home/files.nix`](../../nix/home/files.nix)).

## Files

| File | Purpose |
|---|---|
| `settings.local.json` | Active permissions and tool access |
| `settings.template.json` | Starter template for new machines |
| `README.md` | This file |

## How it's wired

`nix/home/files.nix` declares:

```nix
home.file.".claude/settings.local.json".source = ../../system/.claude/settings.local.json;
home.file.".claude/settings.template.json".source = ../../system/.claude/settings.template.json;
home.file.".claude/README.md".source = ../../system/.claude/README.md;
```

Each file becomes a symlink at `~/.claude/<name>` pointing into the
Nix store, which in turn copies from this directory at build time.

Other contents of `~/.claude/` (transcripts, plugin caches, session
state) are *not* managed — home-manager only owns the three files
above, leaving the rest alone.

## Editing settings

```bash
$EDITOR ~/.dotfiles/system/.claude/settings.local.json

# Apply (rebuild reads the new content and updates the symlink target)
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
```

Changes are tracked in git automatically since `settings.local.json`
lives inside the dotfiles repo.

## New-machine setup

There's no separate step. `setup.sh` runs `darwin-rebuild switch`,
which activates home-manager, which creates the symlinks. As long as
the Claude Code app is installed (it is, via the `claude` cask in
`homebrew.nix`), the settings apply on first launch.
