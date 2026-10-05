# Documentation index

Canonical documentation for this dotfiles repository. Written to be
precise enough for both humans and AI agents making changes.

| Doc | Read it when you need to… |
|---|---|
| [architecture.md](architecture.md) | Understand the flake wiring, module layering, and the host-descriptor contract |
| [hosts.md](hosts.md) | See what each host is, or onboard a new Mac |
| [packages.md](packages.md) | Add/remove software; decide Nix vs Homebrew vs Mac App Store |
| [shell-and-dotfiles.md](shell-and-dotfiles.md) | Change zsh config, symlink a new dotfile, or understand which files must NOT be symlinked |
| [secrets.md](secrets.md) | Reference a secret from Proton Pass (`pass-get`/`pass-render`), or onboard a machine to the vault |
| [claude-code.md](claude-code.md) | Manage Claude Code settings, agents, commands, skills; the two lanes (`cc-personal`/`cc-work`), guards, codemem memory |
| [agent-workflow.md](agent-workflow.md) | Use or extend the multi-agent workflow (`/flow`, planner/…), per-lane model tiers |
| [client-tooling.md](client-tooling.md) | Set up per-client Claude Code tooling (private repo + `cc-tooling`), onboard/switch clients |
| [nvim-cheatsheet.md](nvim-cheatsheet.md) | Look up Neovim keybindings while learning the NixVim setup |
| [operations.md](operations.md) | Rebuild, update, health-check, back up, troubleshoot |
| [ci.md](ci.md) | Understand or modify the fresh-install CI workflow |

## The five rules that prevent most mistakes

1. **Every change needs `git add` before it works.** Nix flakes only
   see git-tracked files. A new file that isn't staged is invisible to
   `darwin-rebuild` and fails with "path does not exist".
2. **Rebuilds require sudo**:
   `sudo darwin-rebuild switch --flake ~/.dotfiles/nix#<host> -v`
   (host = `m5`, or `$(scutil --get LocalHostName)`).
3. **Never symlink files that apps rewrite at runtime**
   (`~/.claude/settings.json`, `~/.claude-work/settings.json`,
   `~/.docker/config.json`). See
   [shell-and-dotfiles.md](shell-and-dotfiles.md#files-that-must-not-be-symlinked).
4. **`homebrew.onActivation.cleanup = "zap"` uninstalls anything not
   declared.** Installing a formula/cask manually without adding it to
   the host's `homebrew.nix` means the next rebuild removes it.
5. **Per-host vs shared:** packages, homebrew, dock, and git identity
   are per-host (`nix/hosts/<name>/`); everything else is shared
   (`nix/modules/` for system, `nix/home/` for user). Don't add
   host-specific things to shared modules.
