# Profile: personal — a personal Mac: personal apps, SSH keys from the
# Proton Pass vault SSH-personal, Claude Code on the Claude Max login
# (sandboxed, and able to push through the same SSH agent), codemem via Max,
# and the Obsidian vault skills. Git uses the personal identity (the default
# in nix/home/git.nix).
{
  systemModules = [
    ./homebrew.nix
    ./packages.nix
  ];
  homeModules = [
    ./claude.nix
    ./ssh.nix
    ./sandbox-git.nix
    ./vault.nix
  ];
}
