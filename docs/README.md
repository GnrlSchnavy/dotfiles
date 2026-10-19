# Documentation index

Canonical documentation for this dotfiles repository. Written to be
precise enough for both humans and AI agents making changes.

| Doc | Read it when you need to… |
|---|---|
| [architecture.md](architecture.md) | Understand the flake wiring, module layering, profiles, and the host-descriptor contract |
| [hosts.md](hosts.md) | See what each host is, or onboard a new Mac |
| [profiles.md](profiles.md) | See what each profile (`dev`, `personal`, `work`) puts on a machine: apps, CLI tools, git identity, Claude Code, Docker |
| [packages.md](packages.md) | Add/remove software; decide Nix vs Homebrew vs Mac App Store |
| [shell-and-dotfiles.md](shell-and-dotfiles.md) | Change zsh config, symlink a new dotfile, or understand which files must NOT be symlinked |
| [ssh.md](ssh.md) | Set up or rotate SSH keys (they live in Proton Pass; one vault per profile), onboard a Mac's SSH |
| [secrets.md](secrets.md) | Reference a secret from Proton Pass (`pass-get`/`pass-render`), or onboard a machine to the vault |
| [claude-code.md](claude-code.md) | Manage Claude Code settings, agents, commands, skills; the personal (Max, sandbox) and work (`cc-work`, gateway check) setups; Docker (Colima); codemem memory |
| [agent-workflow.md](agent-workflow.md) | Use or extend the multi-agent workflow (`/flow`, planner/…), model tiers |
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
   (host = `m5`, `work`, or `$DOTFILES_HOST`, which the flake sets on every machine).
3. **Never symlink files that apps rewrite at runtime**
   (`~/.claude/settings.json`, `~/.docker/config.json`). See
   [shell-and-dotfiles.md](shell-and-dotfiles.md#files-that-must-not-be-symlinked).
4. **`homebrew.onActivation.cleanup = "zap"` uninstalls anything not
   declared.** Installing a formula/cask manually without adding it to
   a profile's `homebrew.nix` means the next rebuild removes it.
5. **Profiles vs hosts vs shared:** role-level config (apps, packages,
   git identity, Claude Code backend) goes in `nix/profiles/<role>/`;
   machine-only config (dock, hostname, username) in
   `nix/hosts/<name>/`; everything else is shared (`nix/modules/` for
   system, `nix/home/` for user). Don't add role- or host-specific
   things to shared modules.
