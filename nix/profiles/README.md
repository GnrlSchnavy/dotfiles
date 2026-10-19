# Profiles

What each profile puts on a machine — apps, CLI tools, git identity,
Claude Code, Docker — is described in
[`docs/profiles.md`](../../docs/profiles.md). This file covers how
profiles are wired.

A profile is the config for one **role** a machine plays. Each host
descriptor (`nix/hosts/<name>/default.nix`) lists its profiles; the flake
adds each profile's modules ahead of the host's own.

| Profile | Used by | What it adds |
|---|---|---|
| [`dev`](dev/) | every machine | Dev apps and CLI tools (`homebrew.nix`, `packages.nix`), the Colima Docker engine (`docker.nix`) |
| [`personal`](personal/) | `m5` | Personal apps; Claude Code on Claude Max, sandboxed (`claude.nix`), SSH keys from the Proton Pass vault `SSH-personal` (`ssh.nix`), git push from the sandbox (`sandbox-git.nix`), the Obsidian vault skills (`vault.nix`); codemem via Max |
| [`work`](work/) | `work` | Work apps; work git identity; SSH keys from the Proton Pass vault `SSH-work` (`ssh.nix`, plus the `github-personal` alias); Claude Code only through the DevAI/TechNL gateway (`cc-work`), the gateway-check hook, the Ahold `CLAUDE.md` overlay, codemem via the gateway, `cc-tooling` |

A host takes `dev` plus **exactly one** of `personal` / `work`: they set the
same options (codemem's lane, git identity) and the two Claude Code setups
can't share a machine — work client content must never reach the personal
Max login.

## Shape

`<profile>/default.nix` returns two module lists, like a host descriptor:

```nix
{
  systemModules = [ ./homebrew.nix ];   # nix-darwin
  homeModules = [ ./claude.nix ];       # home-manager
}
```

## Where does a change go?

| Change | Place |
|---|---|
| Same on every machine | `nix/modules/` (system) or `nix/home/` (user) |
| Same for every machine of one role (apps, git identity, Claude Code backend) | `nix/profiles/<role>/` |
| Only this machine (dock, hostname, username) | `nix/hosts/<name>/` |

Claude Code and codemem are configured through options declared in
`nix/home/claude-code.nix` (`dotfiles.claude.settings`,
`dotfiles.claude.instructions`) and `nix/home/codemem.nix`
(`dotfiles.codemem.lane`, `dotfiles.codemem.observer`); profiles only set
them.
