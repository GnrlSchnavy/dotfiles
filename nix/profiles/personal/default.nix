# Profile: personal — a personal Mac: personal apps, Claude Code on the
# Claude Max login (sandboxed, with git push through an ssh-agent relay),
# codemem via Max, and the Obsidian vault skills. Git uses the personal
# identity (the default in nix/home/git.nix).
{
  systemModules = [
    ./homebrew.nix
    ./packages.nix
  ];
  homeModules = [
    ./claude.nix
    ./ssh-agent-relay.nix
    ./vault.nix
  ];
}
